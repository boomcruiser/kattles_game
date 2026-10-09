"""Generate an episode's audio from its manifest (episodes/<ep>_audio.json) with ElevenLabs:
voice lines (TTS, eleven_v3 delivery tags in "say"; or a sound effect for "sfx" lines),
sound effects, music beds and ambience loops. Existing files are skipped; delete one to regenerate.
Voice files are named <who>_<slug(text)>.mp3 — the same slug Director.say() looks up.
Usage: ../.venv-sprite/bin/python tools/gen_audio.py episodes/ep1_audio.json"""
import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

API = "https://api.elevenlabs.io/v1"


def key() -> str:
    for line in Path("../kattles_rust/.env").read_text().splitlines():
        if line.startswith("ELEVENLABS_API_KEY="):
            return line.split("=", 1)[1].strip().strip("'\"")
    raise SystemExit("ELEVENLABS_API_KEY missing")


def slug(text: str) -> str:
    """Must match Director._slug()."""
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")[:48]


def post(path: str, body: dict, out: Path) -> None:
    req = urllib.request.Request(f"{API}{path}", data=json.dumps(body).encode(),
                                 headers={"xi-api-key": KEY, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            out.write_bytes(r.read())
        print("ok ", out)
    except urllib.error.HTTPError as e:
        print("ERR", out, e.code, e.read()[:200])


def trim(out: Path) -> None:
    """Cut leading/trailing silence so lines butt up against each other."""
    tmp = out.with_suffix(".tmp.mp3")
    af = ("silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
          "areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.12,areverse")
    if subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(out), "-af", af, str(tmp)]).returncode == 0:
        tmp.replace(out)


def tts(voice: str, text: str, out: Path) -> None:
    body = {"text": text, "model_id": "eleven_v3"}
    if "voice_settings" in m:            # eleven_v3 stability: 0 creative, 0.5 natural, 1 robust
        body["voice_settings"] = m["voice_settings"]
    post(f"/text-to-speech/{voice}?output_format=mp3_44100_128", body, out)
    if out.exists():
        trim(out)


def sfx(prompt: str, secs: float, out: Path, loop: bool = False) -> None:
    body = {"text": prompt, "duration_seconds": secs, "prompt_influence": 0.5}
    if loop:
        body["loop"] = True
    post("/sound-generation", body, out)


KEY = key()
m = json.loads(Path(sys.argv[1]).read_text())
root = Path(m["dir"])
for sub in ("vo", "sfx", "amb"):
    (root / sub).mkdir(parents=True, exist_ok=True)

for line in m["lines"]:
    out = root / "vo" / f"{line['who']}_{slug(line['text'])}.mp3"
    if out.exists():
        continue
    if "sfx" in line:
        sfx(line["sfx"], line.get("secs", 2.0), out)
    else:
        tts(m["voices"][line["who"]], line.get("say", line["text"]), out)

for name, (prompt, secs) in m["sfx"].items():
    out = root / "sfx" / f"{name}.mp3"
    if not out.exists():
        sfx(prompt, secs, out)

for name, (prompt, ms) in m.get("music", {}).items():   # instrumental beds
    (root / "music").mkdir(exist_ok=True)
    out = root / "music" / f"{name}.mp3"
    if not out.exists():
        post("/music", {"prompt": prompt, "music_length_ms": ms, "force_instrumental": True}, out)

for name, (prompt, secs) in m["ambience"].items():
    out = root / "amb" / f"{name}.mp3"
    if not out.exists():
        sfx(prompt, secs, out, loop=True)

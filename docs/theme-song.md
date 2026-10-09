# "The Kattles Show" — theme song

**Status:** lyrics locked. Music not generated yet.

## Lyrics

> They're stompin' in the valley, they're boilin' in the town,
> There's a princess on the throne tryin' to calm 'em all down —
> **Moo moo! Hiss hiss!**
> There's Hybrids in the hollow — half kettle, half cow!
> And Kattlefish splashin' in the lagoon — *"Arr, take a bow!"*
> There's a villain in the slammer and a puppy on the go…
> **It's the Kattles Show!**

Each line introduces someone: Cattles/Kettles, Princess Kate, Hybrids, Kattlefish
(Captain Gill's "Arr"), Rusty + Dukie.

## Direction
- TV-show theme: catchy like South Park's, but nicer to listen to, Teen Titans–style energy.
- Fast, upbeat pop-punk with group vocals; ~20–25s.
- "Moo moo! Hiss hiss!" — one-time segue between the two halves: low goofy "moo moo",
  hissed/whispered "hiss hiss", call-and-response.
- "Arr, take a bow!" — shouted ad-lib in a pirate voice (different singer).
- "It's the Kattles Show!" — big group shout; end on a kettle-whistle shriek / cowbell.
- Instrument color: banjo/fiddle stabs (Cattle Valley), tuba/brass (Steamtown).
- Never use or imitate Princess Kate's voice.

## "Moo moo! Hiss hiss!" sting (done)
Recurring ~3s vocal hook (song segue + scene transitions). Sung, not spoken — TTS /
character voices read it with speech cadence, and sound-effect models can't do words.
- `assets/audio/moo_hiss_sting.mp3` — **the one**: a cappella pop-punk group vocal, sung
  "Moo moo", whispered "hiss hiss".
- `assets/audio/moo_hiss_alt.mp3` — backup take (separate "moo moo" if needed).
- Made with ElevenLabs Music + a composition plan (`tools/moo_hiss_plan.json`): one 4s
  a cappella section, lyrics fixed, instruments in the negative styles. POST it to
  `https://api.elevenlabs.io/v1/music` with `xi-api-key`.

## Full song (done) — `assets/audio/theme/`
Every version = the a cappella sting as a cold-open intro, then the band (~22s total).
**Default: `hardrock1.mp3`** (used by EP1). Others are kept for episode-themed variants.

| File | Style | Lyric notes |
|---|---|---|
| hardrock1 | 70s hard rock, cowbell | complete ("calm" may read as "cut") |
| hardrock2 | 70s hard rock, cowbell | Kattlefish line garbled, no "Arr" |
| grunge1 | 90s grunge | drops "Hybrids" + villain line |
| grunge2 | 90s grunge | no villain line, long "Show!" |
| edm1 | EDM | word-perfect |
| eurobeat1 | 90s eurobeat | near-perfect |
| poppunk1 | early-2000s pop punk | "slammer" → "summer" |
| poppunk2 | early-2000s pop punk | "lagoon"/"Arr" smudged |
| rap1 | hip hop | no "Arr, take a bow" |

How they were made:
- ElevenLabs Music composition plans `tools/theme_plan_<style>.json`: verse 1 (7s) → verse 2
  (8.5s, "no break") → outro (3.5s). Swap `positive_global_styles` for a new genre.
- Don't ask the model for a silent break — it fills it with band anyway, and splicing a gap
  out sounds wrong. Put the sting at the start instead.
- Prepend the sting with ffmpeg: sting trimmed 0.12–2.95s, loudnorm -14 LUFS, 0.13s fade,
  then the song with its leading silence trimmed.
- Lyric check without ears: local faster-whisper (`small.en`) in `../.venv-sprite`.
- Name artists? No — describe the style (ElevenLabs refuses artist names).

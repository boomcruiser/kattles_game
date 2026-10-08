"""Jail set for episodes: the kattles_web bg-jail painting + a bars-only overlay cut from it,
so puppets can stand *behind* the bars (cell) or in front (visitors).
Run: ../.venv-sprite/bin/python tools/make_jail_set.py"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

SRC = Path("../kattles_web/app/assets/images/Kattles/KattlesDay/bg-jail.png")
OUT = Path("assets/sets")
COLS = [(68, 124), (246, 300), (434, 488), (664, 724), (876, 936)]  # vertical bars (x)
ROWS = [(55, 185), (780, 855), (1395, 1515)]                         # crossbars (y)

im = Image.open(SRC).convert("RGB")
w, h = im.size
mask = np.zeros((h, w), np.float32)
for a, b in COLS:
    mask[:, a:b] = 1
for a, b in ROWS:
    mask[a:b, :] = 1
mask = np.clip(gaussian_filter(mask, 2.0) * 1.15, 0, 1)
bars = np.dstack([np.asarray(im), (mask * 255).astype(np.uint8)])
OUT.mkdir(parents=True, exist_ok=True)
im.save(OUT / "jail_cell.png")
Image.fromarray(bars, "RGBA").save(OUT / "jail_bars.png")
print("wrote", OUT / "jail_cell.png", OUT / "jail_bars.png", (w, h))

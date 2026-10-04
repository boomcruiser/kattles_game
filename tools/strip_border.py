"""Remove a generated solid-color "sticker" border around a character.

Usage: ../.venv-sprite/bin/python tools/strip_border.py <png> [--color orange]

Clears pixels of the border color that are connected (through border-colored pixels) to
the transparent outside, so interior pixels of the same hue (e.g. horn stripes, separated
from the edge by the dark outline) are kept. Overwrites the file.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

COLORS = {
    # pure saturated orange stroke gpt-image-1 sometimes adds to sticker-style art
    "orange": lambda r, g, b: (r > 215) & (g > 95) & (g < 185) & (b < 45),
}


def main(path, color="orange"):
    im = np.array(Image.open(path).convert("RGBA"))
    r, g, b, a = (im[..., i].astype(int) for i in range(4))
    band = COLORS[color](r, g, b) & (a > 0)
    outside = a == 0
    lab, n = ndimage.label(band | outside)
    touching = np.unique(lab[outside])
    strip = band & np.isin(lab, touching[touching > 0])
    im[..., 3] = np.where(strip, 0, im[..., 3])
    Image.fromarray(im).save(path)
    print(f"stripped {int(strip.sum())} border px")


if __name__ == "__main__":
    main(sys.argv[1], *(sys.argv[3:4] if "--color" in sys.argv else []))

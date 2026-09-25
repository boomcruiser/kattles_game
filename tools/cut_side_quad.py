"""Cut a left-facing side-profile quadruped into body + 4 legs.

Usage: ../.venv-sprite/bin/python tools/cut_side_quad.py <name>

Each leg is a region (polygon, image coords) plus a hip pivot. The leg part keeps
the region's pixels from `top` down (overlaps up into the torso); the body drops
the region's pixels from `cut` down. Every part is reduced to its largest
connected component. Writes assets/<name>_side/{body,leg1..leg4}.png, a magenta
_cut.png check, a _sidewalk.png filmstrip, and prints the Godot pivots.

Leg order convention: leg1 = far front, leg2 = near front, leg3 = far back,
leg4 = near back. Draw order: leg1, leg3, Body, leg2, leg4.
Diagonal gait: (leg2, leg3) in phase, (leg1, leg4) opposite.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent

# Per-character config. Polygons are generous; the alpha mask trims them.
CONFIGS = {
    "daisybell": {
        "legs": {
            "leg1": {  # far front
                "poly": [(200, 690), (402, 690), (378, 765), (371, 830), (371, 1000), (200, 1000)],
                "top": 740, "cut": 780, "hip": (355, 760),
            },
            "leg2": {  # near front (bent)
                "poly": [(402, 690), (545, 690), (545, 1000), (371, 1000), (371, 830), (378, 765)],
                "top": 715, "cut": 780, "hip": (465, 750), "near": True,
            },
            "leg3": {  # far back
                "poly": [(635, 740), (744, 740), (744, 1000), (555, 1000), (555, 900), (630, 790)],
                "top": 750, "cut": 780, "hip": (690, 770),
            },
            "leg4": {  # near back
                "poly": [(744, 690), (1000, 690), (1000, 1000), (744, 1000)],
                "top": 745, "cut": 805, "hip": (835, 780), "near": True,
            },
        },
        "swing": 0.26,
        "bob": 8.0,
    },
}


def largest_cc(mask):
    lab, n = ndimage.label(mask)
    if n <= 1:
        return mask
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    return lab == (int(np.argmax(sizes)) + 1)


def poly_mask(shape, poly):
    img = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(img).polygon(poly, fill=1)
    return np.array(img).astype(bool)


def to_rgba(src, mask, fade=None):
    out = src.copy()
    a = np.where(mask, src[..., 3], 0).astype(np.float32)
    if fade is not None:
        # smoothstep alpha ramp from `top` (0) to `cut` (1) so a near leg drawn over
        # the body blends into it instead of showing a hard cut edge when it rotates
        top, cut = fade
        t = np.clip((np.arange(src.shape[0]) - top) / max(cut - top, 1), 0, 1)[:, None]
        a *= t * t * (3 - 2 * t)
    out[..., 3] = a.astype(np.uint8)
    return Image.fromarray(out)


def rotate_about(img, angle_rad, pivot):
    # PIL rotates counter-clockwise for positive angles; Godot's +rotation is clockwise on screen.
    return img.rotate(-np.degrees(angle_rad), resample=Image.BICUBIC, center=pivot)


def main(name):
    cfg = CONFIGS[name]
    d = ROOT / "assets" / f"{name}_side"
    src = np.array(Image.open(d / "source.png").convert("RGBA"))
    h, w = src.shape[:2]
    alpha = src[..., 3] > 60
    rows = np.arange(h)[:, None]

    body = alpha.copy()
    parts = {}
    for leg, lc in cfg["legs"].items():
        region = poly_mask(src.shape, lc["poly"]) & alpha
        parts[leg] = largest_cc(region & (rows >= lc["top"]))
        body &= ~(region & (rows >= lc["cut"]))
    parts["body"] = largest_cc(body)

    imgs = {}
    for pname, m in parts.items():
        lc = cfg["legs"].get(pname, {})
        fade = (lc["top"], lc["cut"]) if lc.get("near") else None
        imgs[pname] = to_rgba(src, m, fade)
        imgs[pname].save(d / f"{pname}.png")

    # magenta cut check: parts tinted and slightly exploded
    check = Image.new("RGBA", (w, h), (255, 0, 255, 255))
    for pname in ["leg1", "leg3", "body", "leg2", "leg4"]:
        check.alpha_composite(imgs[pname])
    check.save(d / "_cut.png")

    # filmstrip using the same math as the GDScript
    swing, bob = cfg["swing"], cfg["bob"]
    frames = []
    for t in np.linspace(0, 2 * np.pi, 6, endpoint=False):
        pl, pr = np.sin(t), np.sin(t + np.pi)
        rot = {"leg1": swing * pr, "leg4": swing * pr, "leg2": swing * pl, "leg3": swing * pl}
        f = Image.new("RGBA", (w, h), (40, 44, 60, 255))
        by = -bob * abs(np.sin(t))
        for pname in ["leg1", "leg3", "body", "leg2", "leg4"]:
            if pname == "body":
                layer = Image.new("RGBA", (w, h))
                layer.alpha_composite(imgs["body"], (0, int(round(by))))
            else:
                layer = rotate_about(imgs[pname], rot[pname], cfg["legs"][pname]["hip"])
            f.alpha_composite(layer)
        frames.append(f.crop((100, 450, 1024, 1000)).resize((462, 275)))
    strip = Image.new("RGBA", (462 * 3, 275 * 2))
    for i, f in enumerate(frames):
        strip.paste(f, ((i % 3) * 462, (i // 3) * 275))
    strip.save(d / "_sidewalk.png")

    cx, cy = w / 2, h / 2
    print("Godot pivots (position = P - C, offset = -(P - C)):")
    for leg, lc in cfg["legs"].items():
        px, py = lc["hip"][0] - cx, lc["hip"][1] - cy
        print(f"  {leg}: position=Vector2({px:g}, {py:g}) offset=Vector2({-px:g}, {-py:g})")


if __name__ == "__main__":
    main(sys.argv[1])

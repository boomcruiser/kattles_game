"""Cut a left-facing side-profile quadruped into body + 4 legs.

Usage: ../.venv-sprite/bin/python tools/cut_side_quad.py <name>

Each leg is a region (polygon, image coords) plus a hip pivot. The leg part keeps
the region's pixels from `top` down (overlaps up into the torso); the body drops
the region's pixels from `cut` down. Every part is reduced to its largest
connected component. Writes assets/<name>_side/{body,leg1..leg4}.png, a magenta
_cut.png check, a _sidewalk.png filmstrip, and prints the Godot pivots.

Leg order convention: leg1 = far front, leg2 = near front, leg3 = far back,
leg4 = near back. Default draw order: leg1, leg3, Body, leg2, leg4 (override
per character with "order", e.g. when sleeves should cover both front legs).
Walk: 4-beat lateral sequence (see side_quad.gd); the filmstrip mirrors its math.
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
    "fluffhorn": {
        "legs": {
            "leg1": {  # far front
                "poly": [(150, 690), (385, 690), (372, 750), (355, 770), (340, 800), (340, 1000), (150, 1000)],
                "top": 720, "cut": 760, "hip": (270, 745),
            },
            "leg2": {  # near front
                "poly": [(385, 690), (600, 690), (595, 760), (520, 860), (520, 1000), (340, 1000), (340, 800), (355, 770), (372, 750)],
                "top": 700, "cut": 765, "hip": (445, 740), "near": True,
            },
            "leg3": {  # far back
                "poly": [(600, 735), (730, 735), (752, 770), (752, 1000), (520, 1000), (520, 860), (595, 760)],
                "top": 740, "cut": 765, "hip": (665, 755),
            },
            "leg4": {  # near back
                "poly": [(730, 690), (875, 690), (895, 760), (940, 800), (940, 1000), (752, 1000), (752, 770)],
                "top": 725, "cut": 790, "hip": (840, 765), "near": True,
            },
        },
        "swing": 0.26,
        "bob": 8.0,
    },
    "moozie": {
        # front legs come out of sweater cuffs: draw both behind the body so the
        # cuffs hide the joints
        # cuffs hide the joints; front hips sit at the cut line (below the cuff) and
        # "near" here just feathers the leg tops so nothing hard-edged peeks out
        "order": ["leg1", "leg2", "leg3", "body", "leg4"],
        "alpha": 120,  # generated art has a faint ground shadow (alpha ~70-100)
        "legs": {
            "leg1": {  # far front
                "poly": [(100, 760), (300, 760), (300, 1000), (100, 1000)],
                "top": 790, "cut": 834, "hip": (215, 834), "near": True,
            },
            "leg2": {  # near front (behind body, under cuff)
                "poly": [(300, 760), (525, 760), (525, 1000), (300, 1000)],
                "top": 826, "cut": 874, "hip": (368, 874), "near": True,
            },
            "leg3": {  # far back
                "poly": [(620, 760), (772, 760), (772, 1000), (540, 1000)],
                "top": 780, "cut": 808, "hip": (695, 805),
            },
            "leg4": {  # near back
                "poly": [(772, 690), (1000, 690), (1000, 1000), (772, 1000)],
                "top": 745, "cut": 800, "hip": (880, 780), "near": True,
            },
        },
        "swing": 0.26,
        "bob": 8.0,
    },
    "spotilda": {
        # neutral-stance painterly art (matches the other Cattles) + knee joints
        "alpha": 110,  # faint soft ground shadow under the hooves
        "legs": {
            "leg1": {  # far front
                "poly": [(250, 700), (420, 700), (420, 760), (396, 1000), (250, 1000)],
                "top": 745, "cut": 772, "hip": (372, 762), "knee": (366, 818),
            },
            "leg2": {  # near front
                "poly": [(420, 690), (575, 690), (575, 1000), (396, 1000), (420, 760)],
                "top": 715, "cut": 775, "hip": (480, 752), "knee": (478, 815), "near": True,
            },
            "leg3": {  # far back
                "poly": [(575, 700), (747, 700), (747, 1000), (575, 1000)],
                "top": 745, "cut": 768, "hip": (692, 758), "knee": (672, 850),
            },
            "leg4": {  # near back
                "poly": [(747, 690), (880, 690), (880, 1000), (747, 1000)],
                "top": 715, "cut": 782, "hip": (818, 750), "knee": (818, 852), "near": True,
            },
        },
        "scene": {"move_speed": 70, "left_bound": 100, "right_bound": 880, "knee_bend": 0.6},
    },
    "wanderella": {
        # neutral-stance painterly art (portrait + Spotilda side view as refs) + knees
        "alpha": 110,
        "legs": {
            "leg1": {  # far front
                "poly": [(260, 700), (414, 700), (414, 1000), (260, 1000)],
                "top": 740, "cut": 762, "hip": (362, 752), "knee": (356, 822),
            },
            "leg2": {  # near front
                "poly": [(414, 690), (580, 690), (580, 1000), (414, 1000)],
                "top": 712, "cut": 768, "hip": (470, 745), "knee": (466, 824), "near": True,
            },
            "leg3": {  # far back
                "poly": [(580, 700), (752, 700), (752, 1000), (580, 1000)],
                "top": 730, "cut": 752, "hip": (700, 742), "knee": (680, 842),
            },
            "leg4": {  # near back
                "poly": [(752, 690), (900, 690), (900, 1000), (752, 1000)],
                "top": 705, "cut": 772, "hip": (825, 742), "knee": (824, 846), "near": True,
            },
        },
        "scene": {"move_speed": 65, "left_bound": 100, "right_bound": 880, "knee_bend": 0.6},
    },
    "bubblehorn": {
        # Hybrid: faithful regen of the ORIGINAL (pre-cutout) portrait from kattles_web's
        # first commit, mirrored to face left, orange sticker border stripped
        # (tools/strip_border.py). 3/4 view: front legs overlap, split at x~394.
        "alpha": 110,
        "legs": {
            "leg1": {  # far front (behind the near front leg)
                "poly": [(394, 780), (475, 780), (475, 1000), (394, 1000)],
                "top": 800, "cut": 822, "hip": (428, 812), "knee": (428, 872),
            },
            "leg2": {  # near front
                "poly": [(250, 780), (394, 780), (394, 1000), (250, 1000)],
                "top": 795, "cut": 822, "hip": (335, 810), "knee": (335, 876), "near": True,
            },
            "leg3": {  # far back
                "poly": [(645, 770), (820, 770), (820, 1000), (645, 1000)],
                "top": 790, "cut": 808, "hip": (728, 800), "knee": (728, 875),
            },
            "leg4": {  # near back
                "poly": [(475, 790), (645, 790), (645, 1000), (475, 1000)],
                "top": 795, "cut": 822, "hip": (562, 812), "knee": (562, 878), "near": True,
            },
        },
        # cheerful, curious, easily amazed: perky trot
        "scene": {"move_speed": 60, "left_bound": 100, "right_bound": 880, "knee_bend": 0.6},
    },
    "clatterhoof": {
        # Hybrid: faithful regen of the original portrait (style preserved), mirrored.
        # Front-ish 3/4 art (every re-angled regen / pixel edit looked off), so he
        # stomps in place: swing 0 (no fore-aft sweep), fixed step_rate, no knees.
        "alpha": 110,
        "legs": {
            "leg1": {  # far front
                "poly": [(290, 800), (455, 800), (455, 1000), (290, 1000)],
                "top": 810, "cut": 832, "hip": (372, 822),
            },
            "leg2": {  # near front
                "poly": [(455, 800), (604, 800), (604, 1000), (455, 1000)],
                "top": 815, "cut": 840, "hip": (535, 830), "near": True,
            },
            "leg3": {  # far back (peeks out behind the near front leg)
                "poly": [(604, 800), (705, 800), (705, 1000), (604, 1000)],
                "top": 815, "cut": 838, "hip": (650, 828),
            },
            "leg4": {  # near back
                "poly": [(705, 790), (870, 790), (870, 1000), (705, 1000)],
                "top": 805, "cut": 828, "hip": (785, 818), "near": True,
            },
        },
        # big, clumsy, energetic: fast heavy clatter with a bouncy body
        "scene": {"move_speed": 70, "left_bound": 100, "right_bound": 880, "swing": 0,
                  "step_rate": 2.2, "lift": 22, "bob": 6},
    },
    "snortle": {
        # Hybrid: ORIGINAL kattles_web cutout (clean except a fake checkerboard in the
        # handle loop, cleared by pixel edit), mirrored so the spout leads. Front-facing
        # art, so stomp in place. Legs touch side by side: split at the color borders.
        "legs": {
            "leg1": {  # far front (dark)
                "poly": [(240, 780), (359, 780), (359, 1000), (240, 1000)],
                "top": 795, "cut": 812, "hip": (305, 805),
            },
            "leg2": {  # near front (light)
                "poly": [(359, 780), (499, 780), (499, 1000), (359, 1000)],
                "top": 795, "cut": 812, "hip": (428, 805), "near": True,
            },
            "leg3": {  # far back (dark)
                "poly": [(499, 780), (623, 780), (623, 1000), (499, 1000)],
                "top": 795, "cut": 812, "hip": (562, 805),
            },
            "leg4": {  # near back (light)
                "poly": [(623, 780), (780, 780), (780, 1000), (623, 1000)],
                "top": 795, "cut": 812, "hip": (690, 805), "near": True,
            },
        },
        # gruff-but-lovable joker: steady stompy waddle
        "scene": {"move_speed": 55, "left_bound": 100, "right_bound": 880, "swing": 0,
                  "step_rate": 1.8, "lift": 18, "bob": 4},
    },
    "moosteam": {
        # Hybrid: ORIGINAL kattles_web cutout (already a clear 3/4 facing left). Baked-in
        # checkerboard cleared by color flood-fill + everything below the belly line
        # outside the leg columns. Short straight legs: normal sweep walk, no knees.
        "legs": {
            "leg1": {  # far front (dark)
                "poly": [(236, 820), (330, 820), (330, 1000), (236, 1000)],
                "top": 830, "cut": 852, "hip": (284, 840),
            },
            "leg2": {  # near front (white)
                "poly": [(362, 820), (462, 820), (462, 1000), (362, 1000)],
                "top": 830, "cut": 852, "hip": (412, 840), "near": True,
            },
            "leg3": {  # far back (dark)
                "poly": [(568, 820), (662, 820), (662, 1000), (568, 1000)],
                "top": 830, "cut": 852, "hip": (615, 840),
            },
            "leg4": {  # near back (orange)
                "poly": [(690, 810), (800, 810), (800, 1000), (690, 1000)],
                "top": 825, "cut": 852, "hip": (743, 838), "near": True,
            },
        },
        # calm, humble, gentle soul: steady unhurried walk
        "scene": {"move_speed": 50, "left_bound": 100, "right_bound": 880, "lift": 12},
    },
    "puffalo": {
        # Hybrid: ORIGINAL kattles_web cutout (faces left already); baked checker in the
        # handle hole + between the legs cleared by pixel edit. Only 3 legs visible:
        # leg1 is a hidden stub inside the body (drawn behind it).
        "legs": {
            "leg1": {  # far front: hidden, tucked behind the body
                "poly": [(300, 700), (340, 700), (340, 760), (300, 760)],
                "top": 700, "cut": 760, "hip": (320, 730),
            },
            "leg2": {  # near front
                "poly": [(230, 720), (356, 720), (356, 1000), (230, 1000)],
                "top": 735, "cut": 756, "hip": (293, 745), "near": True,
            },
            "leg3": {  # far back (middle visible leg)
                "poly": [(366, 720), (496, 720), (496, 1000), (366, 1000)],
                "top": 735, "cut": 756, "hip": (431, 745),
            },
            "leg4": {  # near back
                "poly": [(532, 720), (662, 720), (662, 1000), (532, 1000)],
                "top": 735, "cut": 756, "hip": (597, 745), "near": True,
            },
        },
        # huge, gentle, calm giant: slow steady stomp, low rumble bob
        "scene": {"move_speed": 38, "left_bound": 100, "right_bound": 880, "swing": 0,
                  "step_rate": 1.3, "lift": 14, "bob": 5},
    },
}


# must match side_quad.gd defaults
WALK = {"swing": 0.22, "duty": 0.65, "lift": 14.0, "bob": 3.0, "knee_bend": 0.7}
KNEE_OVER = 24   # upper leg extends this far below the knee (fills the wedge a bent
                 # knee opens at the front), fading out over its last 16px
KNEE_UNDER = 10  # lower leg extends this far above the knee (feathered)
DEFAULT_ORDER = ["leg1", "leg3", "body", "leg2", "leg4"]
COL_MARGIN = 6  # px of slack either side of a leg's width in the overlap band


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


def to_rgba(src, mask, fade=None, fade_out=None):
    out = src.copy()
    a = np.where(mask, src[..., 3], 0).astype(np.float32)
    if fade_out is not None:
        # smoothstep ramp 1 -> 0 from fade_out[0] down to fade_out[1]
        t = np.clip((np.arange(src.shape[0]) - fade_out[0]) / max(fade_out[1] - fade_out[0], 1), 0, 1)[:, None]
        a *= 1 - t * t * (3 - 2 * t)
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
    order = cfg.get("order", DEFAULT_ORDER)
    d = ROOT / "assets" / f"{name}_side"
    src = np.array(Image.open(d / "source.png").convert("RGBA"))
    h, w = src.shape[:2]
    alpha = src[..., 3] > cfg.get("alpha", 60)
    rows = np.arange(h)[:, None]

    body = alpha.copy()
    parts = {}
    for leg, lc in cfg["legs"].items():
        region = poly_mask(src.shape, lc["poly"]) & alpha
        # above the cut, keep only the leg's own width (at the cut rows) so belly
        # pixels in the overlap band don't swing out below the body silhouette
        cols = np.where(region[lc["cut"]:lc["cut"] + 20].any(axis=0))[0]
        m = COL_MARGIN
        in_cols = np.zeros(w, bool)
        in_cols[max(cols.min() - m, 0):cols.max() + m + 1] = True
        band = region & (rows >= lc["top"]) & ((rows >= lc["cut"]) | in_cols[None, :])
        parts[leg] = largest_cc(band)
        body &= ~(region & (rows >= lc["cut"]))
    parts["body"] = largest_cc(body)

    # optional knee split: upper = hip..knee (+overlap), lower = knee..hoof; the lower
    # part pivots at the knee and is drawn over the upper
    for leg, lc in cfg["legs"].items():
        if "knee" in lc:
            ky = lc["knee"][1]
            parts[leg + "_lo"] = parts[leg] & (rows >= ky - KNEE_UNDER)
            parts[leg] = parts[leg] & (rows < ky + KNEE_OVER)

    imgs = {}
    for pname, m in parts.items():
        lc = cfg["legs"].get(pname, {})
        if pname.endswith("_lo"):
            ky = cfg["legs"][pname[:-3]]["knee"][1]
            fade = (ky - KNEE_UNDER, ky + 2)
        else:
            fade = (lc["top"], lc["cut"]) if lc.get("near") else None
        fade_out = None
        if "knee" in lc:
            ky = lc["knee"][1]
            fade_out = (ky + KNEE_OVER - 16, ky + KNEE_OVER)
        imgs[pname] = to_rgba(src, m, fade, fade_out)
        imgs[pname].save(d / f"{pname}.png")

    # magenta cut check
    check = Image.new("RGBA", (w, h), (255, 0, 255, 255))
    for pname in order:
        check.alpha_composite(imgs[pname])
        if pname + "_lo" in imgs:
            check.alpha_composite(imgs[pname + "_lo"])
    check.save(d / "_cut.png")

    # filmstrip using the same math as side_quad.gd
    walk = {**WALK, **cfg.get("scene", {})}
    swing, duty, bob, bend = walk["swing"], walk["duty"], walk["bob"], walk["knee_bend"]
    phases = {"leg1": 0.75, "leg2": 0.25, "leg3": 0.5, "leg4": 0.0}
    frames = []
    for p in np.linspace(0, 1, 8, endpoint=False):
        f = Image.new("RGBA", (w, h), (40, 44, 60, 255))
        by = bob * 0.5 * (1 - np.cos(2 * np.pi * 2 * p))
        for pname in order:
            layer = Image.new("RGBA", (w, h))
            if pname == "body":
                layer.alpha_composite(imgs["body"], (0, int(round(by))))
            else:
                lc = cfg["legs"][pname]
                has_knee = "knee" in lc
                lift = 0.0 if has_knee else walk["lift"]
                q = (p + phases[pname]) % 1
                if q < duty:
                    rot, dy, kr = swing - 2 * swing * (q / duty), 0.0, 0.0
                else:
                    s = (q - duty) / (1 - duty)
                    rot = -swing + 2 * swing * (s * s * (3 - 2 * s))
                    dy = -lift * np.sin(np.pi * s)
                    kr = -bend * np.sin(np.pi * s)
                leg_img = imgs[pname].copy()
                if has_knee:
                    leg_img.alpha_composite(rotate_about(imgs[pname + "_lo"], kr, lc["knee"]))
                layer.alpha_composite(rotate_about(leg_img, rot, lc["hip"]), (0, int(round(dy))))
            f.alpha_composite(layer)
        frames.append(f.crop((100, 450, 1024, 1000)).resize((347, 206)))
    strip = Image.new("RGBA", (347 * 4, 206 * 2))
    for i, f in enumerate(frames):
        strip.paste(f, ((i % 4) * 347, (i // 4) * 206))
    strip.save(d / "_sidewalk.png")

    cx, cy = w / 2, h / 2
    print("Godot pivots (position = P - C, offset = -(P - C)):")
    for leg, lc in cfg["legs"].items():
        px, py = lc["hip"][0] - cx, lc["hip"][1] - cy
        print(f"  {leg}: position=Vector2({px:g}, {py:g}) offset=Vector2({-px:g}, {-py:g})")

    if "scene" in cfg:
        write_scene(name, cfg, order, (cx, cy))


def write_scene(name, cfg, order, center):
    """Generate <Name>.tscn: Sprite2D per part on the shared canvas, hips/knees pivoted
    via position/offset, knee lower legs as a "Lower" child of each leg."""
    cx, cy = center
    title = name.capitalize()
    res, nodes = [], []

    def tex(fname):
        res.append(f'[ext_resource type="Texture2D" path="res://assets/{name}_side/{fname}" id="{len(res) + 1}"]')
        return len(res)

    body_id = tex("body.png")
    for pname in order:
        if pname == "body":
            nodes.append(f'[node name="Body" type="Sprite2D" parent="."]\ntexture = ExtResource("{body_id}")')
            continue
        lc = cfg["legs"][pname]
        node = "Leg" + pname[-1]
        hx, hy = lc["hip"][0] - cx, lc["hip"][1] - cy
        nodes.append(f'[node name="{node}" type="Sprite2D" parent="."]\n'
                     f'position = Vector2({hx:g}, {hy:g})\noffset = Vector2({-hx:g}, {-hy:g})\n'
                     f'texture = ExtResource("{tex(pname + ".png")}")')
        if "knee" in lc:
            kx, ky = lc["knee"]
            nodes.append(f'[node name="Lower" type="Sprite2D" parent="{node}"]\n'
                         f'position = Vector2({kx - lc["hip"][0]:g}, {ky - lc["hip"][1]:g})\n'
                         f'offset = Vector2({-(kx - cx):g}, {-(ky - cy):g})\n'
                         f'texture = ExtResource("{tex(pname + "_lo.png")}")')
    props = "\n".join(f"{k} = {float(v)}" if isinstance(v, (int, float)) else f"{k} = {v}"
                      for k, v in cfg["scene"].items())
    out = [f"[gd_scene load_steps={len(res) + 2} format=3]", "",
           '[ext_resource type="Script" path="res://side_quad.gd" id="0"]', *res, "",
           f'[node name="{title}" type="Node2D"]\nscript = ExtResource("0")\n{props}', ""]
    out += [n + "\n" for n in nodes]
    (ROOT / f"{title}.tscn").write_text("\n".join(out))
    print(f"wrote {title}.tscn")


if __name__ == "__main__":
    main(sys.argv[1])

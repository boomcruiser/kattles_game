"""Clear a baked checkerboard / flat background from sticker-style art and keep the main
figure: flood-fill from the border through pixels that match the border's dominant
low-saturation colours, then keep the largest opaque component.
Usage: ../.venv-sprite/bin/python tools/clear_checker.py <in.png> <out.png> [tol]"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

src, dst = sys.argv[1], sys.argv[2]
tol = float(sys.argv[3]) if len(sys.argv) > 3 else 30.0

im = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32)
rgb = im[..., :3]
h, w = rgb.shape[:2]

# dominant border colours (quantised), usually the two checker shades or one flat grey
border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
q = (border // 16).astype(int)
keys, counts = np.unique(q[:, 0] * 256 + q[:, 1] * 16 + q[:, 2], return_counts=True)
top = keys[np.argsort(counts)[::-1][:3]]
colours = [border[(q[:, 0] * 256 + q[:, 1] * 16 + q[:, 2]) == k].mean(0) for k in top]

sat = rgb.max(-1) - rgb.min(-1)
bgish = np.zeros((h, w), bool)
for c in colours:
    bgish |= np.linalg.norm(rgb - c, axis=-1) < tol
bgish &= sat < 40

lab, _ = ndimage.label(bgish)
edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
bg = np.isin(lab, edge[edge > 0])

alpha = np.where(bg, 0, im[..., 3])
fg, n = ndimage.label(alpha > 0)
if n:
    sizes = ndimage.sum(np.ones_like(fg), fg, range(1, n + 1))
    alpha = np.where(fg == 1 + int(np.argmax(sizes)), alpha, 0)
# soften the cut edge a little
alpha = np.minimum(alpha, ndimage.uniform_filter((alpha > 0).astype(np.float32), 3) * 255)

out = np.dstack([rgb, alpha]).astype(np.uint8)
img = Image.fromarray(out, "RGBA")
img = img.crop(img.getbbox())
img.save(dst)
print(dst, img.size)

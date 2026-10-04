"""Generate the Noor Qur'an launcher icon.

Design: deep emerald radial gradient with a gold eight-pointed Islamic star
(Rub el Hizb) ring cradling a gold crescent moon and star. Drawn at 4x and
downscaled for clean anti-aliased edges.

Run:  python tools/make_icon.py
"""
import math
import os
from PIL import Image, ImageDraw, ImageChops, ImageFilter

S = 4                       # supersample factor
BASE = 1024                 # logical canvas
C = BASE * S                # working canvas
LANCZOS = Image.Resampling.LANCZOS

EMERALD_LIGHT = (26, 160, 133)   # #1AA085
EMERALD = (14, 110, 92)          # #0E6E5C
EMERALD_DEEP = (8, 60, 50)       # #083C32
GOLD = (232, 199, 102)           # #E8C766


def radial_bg(size):
    """Emerald radial gradient, light near the top-centre."""
    img = Image.new("RGB", (size, size), EMERALD_DEEP)
    px = img.load()
    cx, cy = size * 0.5, size * 0.40
    maxd = math.hypot(size * 0.62, size * 0.72)
    for y in range(size):
        for x in range(size):
            d = min(1.0, math.hypot(x - cx, y - cy) / maxd) ** 0.85
            if d < 0.5:
                t = d / 0.5
                a, b = EMERALD_LIGHT, EMERALD
            else:
                t = (d - 0.5) / 0.5
                a, b = EMERALD, EMERALD_DEEP
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    return img


def octagram_mask(size, radius, cx, cy):
    """Filled eight-pointed star = union of two squares."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    for rot in (0, math.pi / 4):
        pts = [(cx + radius * math.cos(rot + i * math.pi / 2),
                cy + radius * math.sin(rot + i * math.pi / 2)) for i in range(4)]
        d.polygon(pts, fill=255)
    return m


def crescent_mask(size, cx, cy, r_out, r_in, off):
    """Crescent = big circle minus an offset circle."""
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([cx - r_out, cy - r_out, cx + r_out, cy + r_out], fill=255)
    hole = Image.new("L", (size, size), 0)
    ImageDraw.Draw(hole).ellipse([cx + off - r_in, cy - r_in, cx + off + r_in, cy + r_in], fill=255)
    return ImageChops.subtract(m, hole)


def star_mask(size, cx, cy, r):
    """Five-pointed star."""
    m = Image.new("L", (size, size), 0)
    pts = []
    for i in range(10):
        rad = r if i % 2 == 0 else r * 0.42
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m


def overlay(base, mask, color, alpha=255):
    layer = Image.new("RGBA", base.size, tuple(color) + (alpha,))
    return Image.alpha_composite(base, Image.composite(layer, Image.new("RGBA", base.size, (0, 0, 0, 0)), mask))


def build_foreground(size):
    """Transparent layer holding the gold emblem, inside the adaptive safe zone."""
    fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = size / 2
    R = size * 0.315
    stroke = size * 0.028

    ring = ImageChops.subtract(octagram_mask(size, R, cx, cy),
                               octagram_mask(size, R - stroke, cx, cy))
    glow = ring.filter(ImageFilter.GaussianBlur(size * 0.018))
    fg = overlay(fg, glow, GOLD, 150)
    fg = overlay(fg, ring, GOLD)

    cres = crescent_mask(size, cx - size * 0.012, cy, size * 0.175, size * 0.175, size * 0.075)
    fg = overlay(fg, cres, GOLD)
    fg = overlay(fg, star_mask(size, cx + size * 0.115, cy - size * 0.02, size * 0.062), GOLD)
    return fg


def rounded_mask(size, frac=0.235):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1], radius=size * frac, fill=255)
    return m


def circle_mask(size):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size - 1, size - 1], fill=255)
    return m


def scaled_fg(size, scale, dx=0.0, dy=0.0):
    """Return the emblem scaled about the centre and shifted by (dx,dy)*size."""
    side = int(size * scale)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    emblem = build_foreground(side)
    layer.paste(emblem, (int(size / 2 - side / 2 + dx * size),
                         int(size / 2 - side / 2 + dy * size)), emblem)
    return layer


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    res = os.path.join(root, "android", "app", "src", "main", "res")
    web_icons = os.path.join(root, "web", "icons")
    os.makedirs(web_icons, exist_ok=True)

    bg = radial_bg(C).convert("RGBA")
    fg = build_foreground(C)
    full = Image.alpha_composite(bg, fg)

    legacy_rounded = full.copy()
    legacy_rounded.putalpha(rounded_mask(C))
    legacy_round = full.copy()
    legacy_round.putalpha(circle_mask(C))

    dens = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, mult in dens.items():
        d = os.path.join(res, f"mipmap-{name}")
        os.makedirs(d, exist_ok=True)
        s = int(48 * mult)
        legacy_rounded.resize((s, s), LANCZOS).save(os.path.join(d, "ic_launcher.png"))
        legacy_round.resize((s, s), LANCZOS).save(os.path.join(d, "ic_launcher_round.png"))
        fsz = int(108 * mult)
        build_foreground(fsz).save(os.path.join(d, "ic_launcher_foreground.png"))

    legacy_rounded.resize((192, 192), LANCZOS).save(os.path.join(web_icons, "Icon-192.png"))
    legacy_rounded.resize((512, 512), LANCZOS).save(os.path.join(web_icons, "Icon-512.png"))
    # Maskable: emblem shrunk to ~72% so it survives circular cropping.
    maskable = Image.alpha_composite(bg, scaled_fg(C, 0.72))
    maskable.resize((192, 192), LANCZOS).save(os.path.join(web_icons, "Icon-maskable-192.png"))
    maskable.resize((512, 512), LANCZOS).save(os.path.join(web_icons, "Icon-maskable-512.png"))
    legacy_rounded.resize((64, 64), LANCZOS).save(os.path.join(root, "web", "favicon.png"))
    legacy_rounded.resize((512, 512), LANCZOS).save(os.path.join(root, "_icon_preview.png"))
    print("icons written ->", res, "and", web_icons)


if __name__ == "__main__":
    main()

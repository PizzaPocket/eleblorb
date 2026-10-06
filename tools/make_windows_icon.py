#!/usr/bin/env python3
"""Builds assets/ui/eleblorbs.ico: the Blorb alone on transparency.

macOS icons need an opaque tile (the OS masks them to a squircle), but a
Windows icon can be just the shape. The source is eleblorbs_app_icon.svg with
its white background rectangle ignored; its paths are plain M/L polylines and
one horizontal linear gradient, so they are rendered here directly.
"""
import re
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "assets/ui/eleblorbs_app_icon.svg"
OUT = ROOT / "assets/ui/eleblorbs.ico"
SIZES = [16, 24, 32, 48, 64, 128, 256]
SS = 8  # supersampling for clean edges
MASTER = 1024
MARGIN = 0.04


def parse():
    text = SVG.read_text()
    stops = [(float(o) / 100, c) for o, c in re.findall(r'offset="([\d.]+)%" stop-color="(#[0-9a-fA-F]{6})"', text)]
    paths = []
    for fill, d in re.findall(r'<path fill="([^"]+)" d="([^"]+)"', text):
        pts = [(float(x), float(y)) for x, y in re.findall(r"[ML]\s*([-\d.]+)[ ,]([-\d.]+)", d)]
        paths.append((fill, pts))
    return stops, paths


def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def gradient_at(stops, t):
    for (a, ca), (b, cb) in zip(stops, stops[1:]):
        if a <= t <= b:
            u = 0 if b == a else (t - a) / (b - a)
            ra, rb = hex_rgb(ca), hex_rgb(cb)
            return tuple(round(ra[i] + (rb[i] - ra[i]) * u) for i in range(3))
    return hex_rgb(stops[-1][1])


def render():
    stops, paths = parse()
    body = paths[0][1]
    xs, ys = [p[0] for p in body], [p[1] for p in body]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    side = max(x1 - x0, y1 - y0) / (1 - 2 * MARGIN)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    n = MASTER * SS
    scale = n / side

    def to_px(p):
        return ((p[0] - cx) * scale + n / 2, (p[1] - cy) * scale + n / 2)

    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    # Body: gradient fill clipped by the silhouette, left to right across its bbox.
    mask = Image.new("L", (n, n), 0)
    ImageDraw.Draw(mask).polygon([to_px(p) for p in body], fill=255)
    bx0, bx1 = to_px((x0, 0))[0], to_px((x1, 0))[0]
    strip = Image.new("RGB", (1024, 1))
    for i in range(1024):
        strip.putpixel((i, 0), gradient_at(stops, i / 1023))
    ramp = strip.resize((max(1, round(bx1 - bx0)), n), Image.BILINEAR)
    grad = Image.new("RGB", (n, n), hex_rgb(stops[-1][1]))
    grad.paste(ramp, (round(bx0), 0))
    img.paste(grad, (0, 0), mask)
    draw = ImageDraw.Draw(img)
    for fill, pts in paths[1:]:
        draw.polygon([to_px(p) for p in pts], fill=hex_rgb(fill) + (255,))
    return img.resize((MASTER, MASTER), Image.LANCZOS)


def main():
    master = render()
    master.save(ROOT / "wip/windows_icon_preview.png")
    master.save(OUT, format="ICO", sizes=[(s, s) for s in SIZES])
    print("wrote", OUT)


if __name__ == "__main__":
    main()

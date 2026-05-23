#!/usr/bin/env python3
"""Generate Play Store assets for Neon 2048.

Produces:
  tool/store-assets/icon-512.png             — square app icon (Play Console)
  tool/store-assets/feature-graphic-1024x500.png — top-of-listing banner

Uses the bundled Orbitron variable font so the look matches the in-app type.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO = Path(__file__).resolve().parent.parent
FONT_PATH = REPO / "assets" / "fonts" / "Orbitron.ttf"
OUT_DIR = REPO / "tool" / "store-assets"

# Palette — mirrors lib/theme/neon_theme.dart.
BG_DARK = (3, 6, 13)
BG_LIGHT = (7, 16, 24)
PANEL = (8, 19, 32)
EMPTY_CELL = (12, 26, 41)
NEON = (34, 230, 255)
NEON_HOT = (234, 251, 255)
NEON_DIM = (20, 84, 106)
TEXT_DIM = (111, 147, 166)


def load_font(size: int, weight: int = 700) -> ImageFont.FreeTypeFont:
    """Load Orbitron at a target variable-font weight (Orbitron supports 400–900)."""
    font = ImageFont.truetype(str(FONT_PATH), size)
    try:
        font.set_variation_by_axes([weight])
    except Exception:
        # Older Pillow / non-variable: best effort by name.
        try:
            name = b"Black" if weight >= 850 else b"Bold" if weight >= 650 else b"Regular"
            font.set_variation_by_name(name)
        except Exception:
            pass
    return font


def gradient_bg(size: tuple[int, int], top: tuple[int, int, int],
                bottom: tuple[int, int, int]) -> Image.Image:
    """Vertical gradient from `top` to `bottom`."""
    w, h = size
    bg = Image.new("RGB", size)
    px = bg.load()
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return bg.convert("RGBA")


def draw_glow_rect(canvas: Image.Image, rect: tuple[int, int, int, int],
                   radius: int, color: tuple[int, int, int],
                   blur: float, alpha: int = 160) -> None:
    """Composite a soft glow under the spot where a shape will be drawn."""
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(rect, radius=radius, fill=color + (alpha,))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def draw_glow_text(canvas: Image.Image, xy: tuple[int, int], text: str,
                   font: ImageFont.FreeTypeFont,
                   color: tuple[int, int, int], blur: float,
                   alpha: int = 255, anchor: str = "mm") -> None:
    """Draw a blurred copy of `text` then the crisp version on top."""
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text(xy, text, font=font, fill=color + (alpha,), anchor=anchor)
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))
    ImageDraw.Draw(canvas).text(xy, text, font=font, fill=color + (255,), anchor=anchor)


def build_icon() -> Path:
    """Single neon tile in a dark square — reads as the game at a glance."""
    size = 512
    img = gradient_bg((size, size), BG_DARK, BG_LIGHT)

    margin = 38
    tile = (margin, margin, size - margin, size - margin)
    tile_w = size - 2 * margin
    radius = int(tile_w * 0.16)

    # Soft outer glow of the tile.
    draw_glow_rect(img, tile, radius, NEON, blur=30, alpha=120)

    # Tile face + neon border.
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(tile, radius=radius, fill=PANEL + (255,))
    d.rounded_rectangle(tile, radius=radius, outline=NEON + (255,), width=10)

    # Big glowing "2".
    font = load_font(int(tile_w * 0.62), weight=900)
    cx, cy = size // 2, size // 2 + 14  # tiny optical drop for visual centering
    draw_glow_text(img, (cx, cy), "2", font, NEON_HOT, blur=20)

    out = OUT_DIR / "icon-512.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    return out


def build_feature_graphic() -> Path:
    """Title block on the left, four-tile board excerpt on the right."""
    w, h = 1024, 500
    img = gradient_bg((w, h), BG_DARK, BG_LIGHT)

    # Subtle dot grid that fades to the right.
    dots = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dd = ImageDraw.Draw(dots)
    step = 20
    for y in range(step, h, step):
        for x in range(step, w, step):
            a = max(0, 38 - int((x / w) * 32))
            dd.ellipse((x - 1, y - 1, x + 1, y + 1), fill=NEON_DIM + (a,))
    img.alpha_composite(dots)

    # ── Left: title block ───────────────────────────────────────────────
    title_x = 60
    title_baseline_y = 250
    d = ImageDraw.Draw(img)

    eyebrow_font = load_font(22, weight=600)
    d.text((title_x, title_baseline_y - 80), "// NEON GRID",
           font=eyebrow_font, fill=TEXT_DIM + (255,))

    title_font = load_font(80, weight=900)
    draw_glow_text(img, (title_x, title_baseline_y), "NEON 2048",
                   title_font, NEON, blur=14, anchor="lm")

    tag_font = load_font(20, weight=500)
    d.text((title_x, title_baseline_y + 70),
           "TILE-MERGING ON A NEON GRID",
           font=tag_font, fill=TEXT_DIM + (255,))

    # ── Right: a 4×4 board with a few sample tiles ──────────────────────
    board_size = 320
    board_x = w - board_size - 60
    board_y = (h - board_size) // 2

    # Board backdrop + glow.
    d.rounded_rectangle((board_x, board_y, board_x + board_size, board_y + board_size),
                        radius=20, fill=(5, 11, 20, 255))
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).rounded_rectangle(
        (board_x, board_y, board_x + board_size, board_y + board_size),
        radius=20, outline=NEON + (180,), width=5)
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(10)))
    d.rounded_rectangle((board_x, board_y, board_x + board_size, board_y + board_size),
                        radius=20, outline=NEON + (220,), width=2)

    # Empty cells.
    pad = 16
    gap = 10
    cell = (board_size - 2 * pad - 3 * gap) // 4
    for r in range(4):
        for c in range(4):
            cx = board_x + pad + c * (cell + gap)
            cy = board_y + pad + r * (cell + gap)
            d.rounded_rectangle((cx, cy, cx + cell, cy + cell),
                                radius=int(cell * 0.16),
                                fill=EMPTY_CELL + (255,),
                                outline=NEON_DIM + (140,), width=1)

    # Sample tiles climbing in value to show the glow progression.
    edge_for = {
        2:   (61, 110, 136),
        8:   (68, 162, 220),
        32:  (42, 212, 242),
        128: (95, 238, 255),
    }
    samples = [(0, 0, 2), (1, 1, 8), (2, 2, 32), (3, 3, 128)]
    for r, c, value in samples:
        x = board_x + pad + c * (cell + gap)
        y = board_y + pad + r * (cell + gap)
        edge = edge_for[value]
        # tile glow
        draw_glow_rect(img, (x, y, x + cell, y + cell),
                       int(cell * 0.16), edge, blur=cell * 0.18, alpha=140)
        # tile face
        d.rounded_rectangle((x, y, x + cell, y + cell),
                            radius=int(cell * 0.16), fill=(14, 30, 50, 255),
                            outline=edge + (255,), width=3)
        # number
        digits = len(str(value))
        scale = 0.42 if digits <= 2 else 0.34 if digits == 3 else 0.27
        fs = int(cell * scale)
        font = load_font(fs, weight=700)
        draw_glow_text(img, (x + cell // 2, y + cell // 2 + 2),
                       str(value), font, edge, blur=cell * 0.08)

    out = OUT_DIR / "feature-graphic-1024x500.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    return out


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    icon = build_icon()
    feature = build_feature_graphic()
    print(f"icon:    {icon}  ({icon.stat().st_size // 1024} KB)")
    print(f"feature: {feature}  ({feature.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()

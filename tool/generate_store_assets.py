#!/usr/bin/env python3
"""Generate Play Store assets for Neon 2048.

Produces:
  tool/store-assets/icon-512.png                  — square app icon
  tool/store-assets/feature-graphic-1024x500.png  — top-of-listing banner
  tool/store-assets/screenshot-*-*.png            — phone screenshots
  tool/store-assets/screenshot-4-promo.png        — synthetic 2048 promo
  tool/store-assets/screenshot-5-promo-2187.png   — synthetic 2187 promo

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
# 2187-mode accent — matches NeonTheme.neon2187 / red-ramp 729 step.
NEON_2187 = (255, 90, 200)


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

    # Big glowing "2048" — the brand. 4 digits + Orbitron Black is wide, so
    # the size factor is much smaller than for a single character.
    font = load_font(int(tile_w * 0.34), weight=900)
    cx, cy = size // 2, size // 2 + 8  # tiny optical drop for visual centering
    draw_glow_text(img, (cx, cy), "2048", font, NEON_HOT, blur=14)

    out = OUT_DIR / "icon-512.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    return out


def _draw_pointy_hex(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float,
                     fill: tuple[int, int, int, int] | None,
                     outline: tuple[int, int, int, int] | None,
                     width: int = 1) -> list[tuple[float, float]]:
    """Draw a pointy-top regular hexagon centred at (cx, cy) with circumradius r."""
    import math
    pts = []
    for i in range(6):
        angle = math.pi / 3 * i - math.pi / 2
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    d.polygon(pts, fill=fill, outline=outline, width=width)
    return pts


def _hex_glow(canvas: Image.Image, cx: float, cy: float, r: float,
              color: tuple[int, int, int], blur: float, alpha: int = 150) -> None:
    """Composite a soft glow under a hexagon."""
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    _draw_pointy_hex(ImageDraw.Draw(layer), cx, cy, r,
                     fill=color + (alpha,), outline=None)
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def build_feature_graphic() -> Path:
    """Title block on the left, square + hex board excerpts on the right."""
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

    # Two-mode title: cyan "2048" and pink "2187" side by side.
    title_font = load_font(64, weight=900)
    draw_glow_text(img, (title_x, title_baseline_y), "2048",
                   title_font, NEON, blur=12, anchor="lm")
    # Measure 2048 width for spacing.
    bbox = d.textbbox((0, 0), "2048", font=title_font)
    sep_x = title_x + (bbox[2] - bbox[0]) + 14
    d.text((sep_x, title_baseline_y - 4), "|",
           font=load_font(48, weight=300), fill=NEON_DIM + (255,), anchor="lm")
    draw_glow_text(img, (sep_x + 24, title_baseline_y), "2187",
                   title_font, NEON_2187, blur=12, anchor="lm")

    tag_font = load_font(20, weight=500)
    d.text((title_x, title_baseline_y + 60),
           "TILE-MERGING ON A NEON GRID — SQUARE OR HEX",
           font=tag_font, fill=TEXT_DIM + (255,))

    # ── Right: side-by-side square + hex preview boards ─────────────────
    panel_w = 180
    panel_h = 320
    gap_x = 20
    boards_total_w = panel_w * 2 + gap_x
    boards_x = w - boards_total_w - 60
    boards_y = (h - panel_h) // 2

    # Square mini-board (left panel).
    sq_x = boards_x
    sq_y = boards_y
    d.rounded_rectangle((sq_x, sq_y, sq_x + panel_w, sq_y + panel_w),
                        radius=14, fill=(5, 11, 20, 255))
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).rounded_rectangle(
        (sq_x, sq_y, sq_x + panel_w, sq_y + panel_w),
        radius=14, outline=NEON + (180,), width=4)
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(8)))
    d.rounded_rectangle((sq_x, sq_y, sq_x + panel_w, sq_y + panel_w),
                        radius=14, outline=NEON + (220,), width=2)
    sq_pad = 12
    sq_gap = 7
    sq_cell = (panel_w - 2 * sq_pad - 3 * sq_gap) // 4
    for r in range(4):
        for c in range(4):
            cx = sq_x + sq_pad + c * (sq_cell + sq_gap)
            cy = sq_y + sq_pad + r * (sq_cell + sq_gap)
            d.rounded_rectangle((cx, cy, cx + sq_cell, cy + sq_cell),
                                radius=int(sq_cell * 0.16),
                                fill=EMPTY_CELL + (255,),
                                outline=NEON_DIM + (140,), width=1)
    sq_edge_for = {
        2:   (61, 110, 136),
        8:   (68, 162, 220),
        32:  (42, 212, 242),
        128: (95, 238, 255),
    }
    sq_samples = [(0, 0, 2), (1, 1, 8), (2, 2, 32), (3, 3, 128)]
    for r, c, value in sq_samples:
        x = sq_x + sq_pad + c * (sq_cell + sq_gap)
        y = sq_y + sq_pad + r * (sq_cell + sq_gap)
        edge = sq_edge_for[value]
        draw_glow_rect(img, (x, y, x + sq_cell, y + sq_cell),
                       int(sq_cell * 0.16), edge, blur=sq_cell * 0.18, alpha=140)
        d.rounded_rectangle((x, y, x + sq_cell, y + sq_cell),
                            radius=int(sq_cell * 0.16), fill=(14, 30, 50, 255),
                            outline=edge + (255,), width=2)
        digits = len(str(value))
        scale = 0.42 if digits <= 2 else 0.34 if digits == 3 else 0.27
        fs = int(sq_cell * scale)
        font = load_font(fs, weight=700)
        draw_glow_text(img, (x + sq_cell // 2, y + sq_cell // 2 + 2),
                       str(value), font, edge, blur=sq_cell * 0.08)
    # Label
    d.text((sq_x + panel_w // 2, sq_y + panel_w + 8), "2048",
           font=load_font(18, weight=700), fill=NEON + (220,), anchor="mt")

    # Hex mini-board (right panel).
    hex_x = boards_x + panel_w + gap_x
    hex_y = boards_y
    d.rounded_rectangle((hex_x, hex_y, hex_x + panel_w, hex_y + panel_w),
                        radius=14, fill=(5, 11, 20, 255))
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).rounded_rectangle(
        (hex_x, hex_y, hex_x + panel_w, hex_y + panel_w),
        radius=14, outline=NEON_2187 + (180,), width=4)
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(8)))
    d.rounded_rectangle((hex_x, hex_y, hex_x + panel_w, hex_y + panel_w),
                        radius=14, outline=NEON_2187 + (220,), width=2)
    # 19-cell hex layout (side 3, pointy-top axial).
    import math
    hex_pad = 14
    usable = panel_w - 2 * hex_pad
    hex_cell = min(usable / 8.0, usable / (5 * math.sqrt(3))) * 0.92
    hex_cx = hex_x + panel_w / 2
    hex_cy = hex_y + panel_w / 2
    cells = []
    for r in range(-2, 3):
        q_min = max(-2, -2 - r)
        q_max = min(2, 2 - r)
        for q in range(q_min, q_max + 1):
            cells.append((q, r))
    # Tile palette samples (3, 9, 27, 81) on the red ramp.
    hex_edge_for = {
        3:  (136, 64, 106),
        9:  (184, 73, 122),
        27: (220, 76, 140),
        81: (236, 79, 160),
    }
    hex_samples = {
        (0, 0): 27,
        (-1, 0): 9,
        (1, 0): 9,
        (0, -1): 3,
        (-1, 1): 3,
        (1, -1): 3,
        (0, 1): 81,
    }
    for q, r in cells:
        cx = hex_cx + hex_cell * math.sqrt(3) * (q + r / 2)
        cy = hex_cy + hex_cell * 1.5 * r
        value = hex_samples.get((q, r))
        if value is None:
            _draw_pointy_hex(d, cx, cy, hex_cell * 0.92,
                             fill=EMPTY_CELL + (255,),
                             outline=NEON_DIM + (140,), width=1)
        else:
            edge = hex_edge_for[value]
            _hex_glow(img, cx, cy, hex_cell * 0.92, edge,
                      blur=hex_cell * 0.20, alpha=140)
            _draw_pointy_hex(ImageDraw.Draw(img), cx, cy, hex_cell * 0.92,
                             fill=(14, 30, 50, 255), outline=edge + (255,),
                             width=2)
            digits = len(str(value))
            scale = 0.55 if digits <= 2 else 0.40
            fs = max(8, int(hex_cell * scale))
            font = load_font(fs, weight=700)
            draw_glow_text(img, (cx, cy + 2), str(value), font, edge,
                           blur=hex_cell * 0.08)
    # Label
    d.text((hex_x + panel_w // 2, hex_y + panel_w + 8), "2187",
           font=load_font(18, weight=700), fill=NEON_2187 + (220,), anchor="mt")

    out = OUT_DIR / "feature-graphic-1024x500.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    return out


def pad_to_9_16(img: Image.Image) -> Image.Image:
    """Pad an image horizontally with dark bars to make it exactly 9:16.

    Used to take 1080×2400 emulator captures (9:20) up to 1350×2400 (9:16) so
    they qualify for Play Store promotion eligibility without cropping any
    in-app content. If the image is already wider than 9:16, pads vertically.
    """
    w, h = img.size
    target_w = int(round(h * 9 / 16))
    if target_w == w:
        return img
    if target_w > w:
        canvas = Image.new("RGB", (target_w, h), BG_DARK)
        canvas.paste(img, ((target_w - w) // 2, 0))
        return canvas
    target_h = int(round(w * 16 / 9))
    canvas = Image.new("RGB", (w, target_h), BG_DARK)
    canvas.paste(img, (0, (target_h - h) // 2))
    return canvas


def crop_screenshots() -> list[Path]:
    """Pad the in-repo emulator screenshots to exact 9:16 for Play Store."""
    src_to_out = [
        ("home.png",        "screenshot-1-home.png"),
        ("gameplay.png",    "screenshot-2-gameplay.png"),
        ("high-scores.png", "screenshot-3-high-scores.png"),
    ]
    outs: list[Path] = []
    for src_name, out_name in src_to_out:
        src = REPO / "screenshots" / src_name
        if not src.exists():
            continue
        padded = pad_to_9_16(Image.open(src).convert("RGB"))
        out = OUT_DIR / out_name
        padded.save(out, "PNG", optimize=True)
        outs.append(out)
    return outs


def build_promo_screenshot() -> Path:
    """A portrait 1080×1920 promo screenshot mimicking the in-app layout.

    Curated board state showing the tile palette climbing from 2 to 1024,
    so the listing has a fourth 9:16 image that visibly demonstrates the
    glow progression in one frame.
    """
    w, h = 1080, 1920
    img = gradient_bg((w, h), BG_DARK, BG_LIGHT)
    d = ImageDraw.Draw(img)

    # Header — same shape as the in-app screen.
    eyebrow_font = load_font(28, weight=600)
    d.text((60, 130), "// NEON GRID", font=eyebrow_font, fill=TEXT_DIM + (255,))

    title_font = load_font(140, weight=900)
    draw_glow_text(img, (60, 280), "2048", title_font, NEON, blur=22, anchor="lm")

    # Faux score panels (cosmetic — show what the run reached).
    def score_box(x: int, label: str, value: str, color: tuple[int, int, int]):
        bw, bh = 460, 130
        d.rounded_rectangle((x, 400, x + bw, 400 + bh),
                            radius=20, fill=PANEL + (255,),
                            outline=color + (140,), width=3)
        d.text((x + 28, 422), label, font=load_font(20, weight=600),
               fill=color + (200,))
        d.text((x + 28, 458), value, font=load_font(46, weight=800),
               fill=NEON_HOT + (255,))

    score_box(60,  "SCORE", "12,480", NEON)
    score_box(560, "BEST",  "12,480", (44, 124, 214))  # deep blue

    # Board — same metrics as in-app, just at 880px wide for the portrait.
    board_size = 960
    board_x = (w - board_size) // 2
    board_y = 620

    d.rounded_rectangle((board_x, board_y, board_x + board_size,
                         board_y + board_size),
                        radius=40, fill=(5, 11, 20, 255))

    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).rounded_rectangle(
        (board_x, board_y, board_x + board_size, board_y + board_size),
        radius=40, outline=NEON + (180,), width=10)
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(18)))
    d.rounded_rectangle((board_x, board_y, board_x + board_size,
                         board_y + board_size),
                        radius=40, outline=NEON + (220,), width=4)

    pad = 38
    gap = 22
    cell = (board_size - 2 * pad - 3 * gap) // 4
    for r in range(4):
        for c in range(4):
            cx = board_x + pad + c * (cell + gap)
            cy = board_y + pad + r * (cell + gap)
            d.rounded_rectangle((cx, cy, cx + cell, cy + cell),
                                radius=int(cell * 0.16),
                                fill=EMPTY_CELL + (255,),
                                outline=NEON_DIM + (140,), width=2)

    # Climbing values — one tile per diagonal-ish cell, showing the gradient.
    edge_for = {
        2:    (61, 110, 136),
        8:    (68, 162, 220),
        32:   (42, 212, 242),
        128:  (95, 238, 255),
        1024: (223, 252, 255),
    }
    samples = [(0, 1, 2), (1, 0, 8), (2, 2, 128), (3, 1, 32), (3, 3, 1024)]
    for r, c, value in samples:
        x = board_x + pad + c * (cell + gap)
        y = board_y + pad + r * (cell + gap)
        edge = edge_for[value]
        draw_glow_rect(img, (x, y, x + cell, y + cell),
                       int(cell * 0.16), edge, blur=cell * 0.20, alpha=150)
        d.rounded_rectangle((x, y, x + cell, y + cell),
                            radius=int(cell * 0.16),
                            fill=(14, 30, 50, 255),
                            outline=edge + (255,), width=4)
        digits = len(str(value))
        scale = 0.42 if digits <= 2 else 0.34 if digits == 3 else 0.26
        fs = int(cell * scale)
        font = load_font(fs, weight=700)
        draw_glow_text(img, (x + cell // 2, y + cell // 2 + 4),
                       str(value), font, edge, blur=cell * 0.08)

    # Footer — match the in-app neon buttons.
    def button(x: int, label: str, color: tuple[int, int, int], filled: bool):
        bw, bh = 460, 100
        bx, by = x, h - 180
        if filled:
            # Pillow's rounded_rectangle doesn't alpha-blend with what's
            # underneath, so we precompute the tint manually — mirrors the
            # in-app NeonButton's `color.withValues(alpha: 0.18)` over panel.
            fill = tuple(int(PANEL[i] * 0.80 + color[i] * 0.20)
                         for i in range(3)) + (255,)
        else:
            fill = PANEL + (255,)
        d.rounded_rectangle((bx, by, bx + bw, by + bh),
                            radius=20, fill=fill,
                            outline=color + (220,), width=3)
        d.text((bx + bw // 2, by + bh // 2 + 2),
               label, font=load_font(26, weight=700),
               fill=color + (255,), anchor="mm")

    button(60,  "NEW GAME",    NEON,            filled=True)
    button(560, "HIGH SCORES", (44, 124, 214),  filled=False)

    out = OUT_DIR / "screenshot-4-promo.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    return out


def build_promo_screenshot_2187() -> Path:
    """A portrait 1080×1920 promo screenshot of the 2187 hex mode.

    Mirrors the in-app layout — title-as-toggle header (2048 dim, 2187 lit),
    score panels, a side-3 hex board with a curated value ladder showing the
    red tile palette climbing from 3 to 729, and the standard footer buttons.
    """
    import math
    w, h = 1080, 1920
    img = gradient_bg((w, h), BG_DARK, BG_LIGHT)
    d = ImageDraw.Draw(img)

    # Header
    eyebrow_font = load_font(28, weight=600)
    d.text((60, 130), "// NEON GRID", font=eyebrow_font, fill=TEXT_DIM + (255,))

    # Two-mode title — 2048 dim, 2187 bright with glow.
    title_font = load_font(140, weight=900)
    d.text((60, 280), "2048", font=title_font, fill=TEXT_DIM + (255,), anchor="lm")
    # measure 2048 width for separator
    bbox = d.textbbox((0, 0), "2048", font=title_font)
    sep_x = 60 + (bbox[2] - bbox[0]) + 30
    d.text((sep_x, 280 - 12), "|", font=load_font(110, weight=300),
           fill=NEON_DIM + (255,), anchor="lm")
    draw_glow_text(img, (sep_x + 60, 280), "2187", title_font, NEON_2187,
                   blur=22, anchor="lm")

    # Score panels — use 2187 mode accent for SCORE, deep blue for BEST.
    def score_box(x: int, label: str, value: str, color: tuple[int, int, int]):
        bw, bh = 460, 130
        d.rounded_rectangle((x, 400, x + bw, 400 + bh),
                            radius=20, fill=PANEL + (255,),
                            outline=color + (140,), width=3)
        d.text((x + 28, 422), label, font=load_font(20, weight=600),
               fill=color + (200,))
        d.text((x + 28, 458), value, font=load_font(46, weight=800),
               fill=NEON_HOT + (255,))

    score_box(60,  "SCORE", "3,564",  NEON_2187)
    score_box(560, "BEST",  "5,832",  (44, 124, 214))

    # Hex board — match the in-app pointy-top side-3 layout, scaled to 880 wide.
    board_size = 960
    board_x = (w - board_size) // 2
    board_y = 620
    d.rounded_rectangle((board_x, board_y, board_x + board_size,
                         board_y + board_size),
                        radius=40, fill=(5, 11, 20, 255))
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).rounded_rectangle(
        (board_x, board_y, board_x + board_size, board_y + board_size),
        radius=40, outline=NEON_2187 + (180,), width=10)
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(18)))
    d.rounded_rectangle((board_x, board_y, board_x + board_size,
                         board_y + board_size),
                        radius=40, outline=NEON_2187 + (220,), width=4)

    # Compute hex cell radius for the same packing as HexBoardMetrics.
    pad_fraction = 0.06
    usable = board_size - 2 * (board_size * pad_fraction)
    cell_r = min(usable / 8.0, usable / (5 * math.sqrt(3))) * 0.92
    cx0 = board_x + board_size / 2
    cy0 = board_y + board_size / 2

    # Enumerate the 19 cells in row-major order (matches lib/game/hex_logic.dart).
    cells: list[tuple[int, int]] = []
    for r in range(-2, 3):
        q_min = max(-2, -2 - r)
        q_max = min(2, 2 - r)
        for q in range(q_min, q_max + 1):
            cells.append((q, r))

    # Red ramp values for the curated palette demo — matches lib/theme/neon_theme.dart.
    edge_for = {
        3:   (136, 64, 106),
        9:   (184, 73, 122),
        27:  (220, 76, 140),
        81:  (236, 79, 160),
        243: (242, 82, 182),
        729: (255, 90, 200),
    }
    # Curated layout — a winding ladder from 3 to 729 to showcase the ramp.
    samples = {
        (-2, 0): 3,
        (-1, 0): 9,
        (0, 0):  27,
        (1, 0):  81,
        (2, 0):  243,
        (0, 1):  3,
        (-1, 1): 9,
        (0, -1): 729,
    }

    for q, r in cells:
        cx = cx0 + cell_r * math.sqrt(3) * (q + r / 2)
        cy = cy0 + cell_r * 1.5 * r
        value = samples.get((q, r))
        if value is None:
            _draw_pointy_hex(ImageDraw.Draw(img), cx, cy, cell_r * 0.92,
                             fill=EMPTY_CELL + (255,),
                             outline=NEON_DIM + (140,), width=2)
        else:
            edge = edge_for[value]
            _hex_glow(img, cx, cy, cell_r * 0.92, edge,
                      blur=cell_r * 0.20, alpha=150)
            _draw_pointy_hex(ImageDraw.Draw(img), cx, cy, cell_r * 0.92,
                             fill=(14, 30, 50, 255), outline=edge + (255,),
                             width=4)
            digits = len(str(value))
            scale = 0.55 if digits <= 2 else 0.40 if digits == 3 else 0.32
            fs = max(8, int(cell_r * scale))
            font = load_font(fs, weight=700)
            draw_glow_text(img, (cx, cy + 4), str(value), font, edge,
                           blur=cell_r * 0.08)

    # Footer buttons — match the in-app NeonButton style.
    def button(x: int, label: str, color: tuple[int, int, int], filled: bool):
        bw, bh = 460, 100
        bx, by = x, h - 180
        if filled:
            fill = tuple(int(PANEL[i] * 0.80 + color[i] * 0.20)
                         for i in range(3)) + (255,)
        else:
            fill = PANEL + (255,)
        d.rounded_rectangle((bx, by, bx + bw, by + bh),
                            radius=20, fill=fill,
                            outline=color + (220,), width=3)
        d.text((bx + bw // 2, by + bh // 2 + 2),
               label, font=load_font(26, weight=700),
               fill=color + (255,), anchor="mm")

    button(60,  "NEW GAME",    NEON_2187,       filled=True)
    button(560, "HIGH SCORES", (44, 124, 214),  filled=False)

    out = OUT_DIR / "screenshot-5-promo-2187.png"
    img.convert("RGB").save(out, "PNG", optimize=True)
    return out


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    icon = build_icon()
    feature = build_feature_graphic()
    screenshots = crop_screenshots()
    promo = build_promo_screenshot()
    promo_2187 = build_promo_screenshot_2187()
    print(f"icon:    {icon}  ({icon.stat().st_size // 1024} KB)")
    print(f"feature: {feature}  ({feature.stat().st_size // 1024} KB)")
    for s in screenshots:
        with Image.open(s) as im:
            print(f"shot:    {s}  ({im.size[0]}×{im.size[1]}, "
                  f"{s.stat().st_size // 1024} KB)")
    for p in (promo, promo_2187):
        with Image.open(p) as im:
            print(f"promo:   {p}  ({im.size[0]}×{im.size[1]}, "
                  f"{p.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()

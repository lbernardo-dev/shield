#!/usr/bin/env python3
"""Generate high-impact, professional App Store marketing screenshots for MaskID."""

from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / ".asc" / "aso-screenshot-plan.json"
RAW_ROOT = ROOT / ".asc" / "screenshots" / "raw_captures"
FINAL_ROOT = ROOT / ".asc" / "screenshots" / "aso" / "final"
REVIEW_ROOT = ROOT / ".asc" / "screenshots" / "aso" / "review"

WIDTH = 1320
HEIGHT = 2868

# Brand Design Tokens
BG_TOP = (3, 7, 18)        # Ultra deep space black-blue
BG_BOTTOM = (10, 27, 48)   # Rich dark navy
ACCENT_RGB = (32, 199, 217) # Electric Identity Cyan #20C7D9
WHITE = (255, 255, 255)
SUBTITLE_COLOR = (184, 201, 223)
BORDER_COLOR = (46, 61, 82)

# System Fonts
FONT_HEAVY_PATH = "/Library/Fonts/SF-Pro-Display-Heavy.otf"
FONT_BOLD_PATH = "/Library/Fonts/SF-Pro-Display-Bold.otf"
FONT_SEMIBOLD_PATH = "/Library/Fonts/SF-Pro-Text-Semibold.otf"
FONT_MEDIUM_PATH = "/Library/Fonts/SF-Pro-Text-Medium.otf"


def get_font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        for fallback in [
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
        ]:
            try:
                return ImageFont.truetype(fallback, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def create_gradient_canvas(width: int, height: int) -> Image.Image:
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(canvas)
    r1, g1, b1 = BG_TOP
    r2, g2, b2 = BG_BOTTOM
    for y in range(height):
        t = y / float(height)
        r = int(r1 + (r2 - r1) * t)
        g = int(g1 + (g2 - g1) * t)
        b = int(b1 + (b2 - b1) * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    return canvas


def add_ambient_glow(canvas: Image.Image) -> Image.Image:
    """Adds a soft, high-end radial spotlight behind the phone header."""
    glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    center_x, center_y = WIDTH // 2, 1100
    radius = 520
    glow_draw.ellipse(
        [center_x - radius, center_y - radius, center_x + radius, center_y + radius],
        fill=(ACCENT_RGB[0], ACCENT_RGB[1], ACCENT_RGB[2], 42),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    return Image.alpha_composite(canvas, glow)


def rounded_image(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width, image.height), radius=radius, fill=255)
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.paste(image.convert("RGBA"), (0, 0), mask)
    return result


def compose_screenshot(
    raw_path: Path,
    output_path: Path,
    order: int,
    data: dict[str, str],
    locale: str
) -> None:
    badge_text = data["badge"]
    action_text = data["action"]
    title_text = data["title"]
    subtitle_text = data["subtitle"]

    # 1. Base Gradient Canvas + Ambient Glow
    canvas = create_gradient_canvas(WIDTH, HEIGHT)
    canvas = add_ambient_glow(canvas)
    draw = ImageDraw.Draw(canvas)

    # 2. Pill Badge (Centered)
    badge_font = get_font(FONT_SEMIBOLD_PATH, 28)
    badge_box = draw.textbbox((0, 0), badge_text, font=badge_font)
    badge_w = badge_box[2] - badge_box[0]
    badge_h = badge_box[3] - badge_box[1]
    pill_padding_x = 36
    pill_padding_y = 14
    pill_w = badge_w + (pill_padding_x * 2)
    pill_h = badge_h + (pill_padding_y * 2)
    pill_x = (WIDTH - pill_w) // 2
    pill_y = 110

    # Draw Badge Pill
    pill_overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    pill_draw = ImageDraw.Draw(pill_overlay)
    pill_draw.rounded_rectangle(
        [pill_x, pill_y, pill_x + pill_w, pill_y + pill_h],
        radius=pill_h // 2,
        fill=(ACCENT_RGB[0], ACCENT_RGB[1], ACCENT_RGB[2], 30),
        outline=(ACCENT_RGB[0], ACCENT_RGB[1], ACCENT_RGB[2], 100),
        width=2,
    )
    canvas = Image.alpha_composite(canvas, pill_overlay)
    draw = ImageDraw.Draw(canvas)
    draw.text((pill_x + pill_padding_x, pill_y + pill_padding_y - 2), badge_text, font=badge_font, fill=ACCENT_RGB)

    # 3. Main Headline (Two Lines: Action in Cyan, Title in White)
    action_font = get_font(FONT_HEAVY_PATH, 94)
    title_font = get_font(FONT_HEAVY_PATH, 88)

    action_box = draw.textbbox((0, 0), action_text, font=action_font)
    action_w = action_box[2] - action_box[0]
    action_x = (WIDTH - action_w) // 2
    action_y = pill_y + pill_h + 36
    draw.text((action_x, action_y), action_text, font=action_font, fill=ACCENT_RGB)

    title_box = draw.textbbox((0, 0), title_text, font=title_font)
    title_w = title_box[2] - title_box[0]
    title_x = (WIDTH - title_w) // 2
    title_y = action_y + (action_box[3] - action_box[1]) + 8
    draw.text((title_x, title_y), title_text, font=title_font, fill=WHITE)

    # 4. Subtitle (Centered, Clean, Legible)
    sub_font = get_font(FONT_MEDIUM_PATH, 42)
    sub_box = draw.textbbox((0, 0), subtitle_text, font=sub_font)
    sub_w = sub_box[2] - sub_box[0]
    sub_x = (WIDTH - sub_w) // 2
    sub_y = title_y + (title_box[3] - title_box[1]) + 28
    draw.text((sub_x, sub_y), subtitle_text, font=sub_font, fill=SUBTITLE_COLOR)

    # 5. Realistic Device Mockup
    raw = Image.open(raw_path).convert("RGB")
    target_width = 1120
    target_height = round(raw.height * target_width / raw.width)
    raw_resized = raw.resize((target_width, target_height), Image.Resampling.LANCZOS)

    phone_corner_radius = 72
    phone_img = rounded_image(raw_resized, phone_corner_radius)
    phone_x = (WIDTH - target_width) // 2
    phone_y = max(600, sub_y + (sub_box[3] - sub_box[1]) + 52)

    # Multi-level Shadow
    shadow_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_layer)
    # Deep ambient shadow
    sdraw.rounded_rectangle(
        [phone_x - 14, phone_y + 24, phone_x + target_width + 14, phone_y + target_height + 34],
        radius=phone_corner_radius + 12,
        fill=(0, 0, 0, 180),
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(52))

    # Sharp contact shadow
    contact_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(contact_layer)
    cdraw.rounded_rectangle(
        [phone_x - 6, phone_y + 12, phone_x + target_width + 6, phone_y + target_height + 16],
        radius=phone_corner_radius + 4,
        fill=(0, 0, 0, 140),
    )
    contact_layer = contact_layer.filter(ImageFilter.GaussianBlur(18))

    canvas = Image.alpha_composite(canvas, shadow_layer)
    canvas = Image.alpha_composite(canvas, contact_layer)

    # Device Titanium Bezel Frame
    bezel = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(bezel)
    bdraw.rounded_rectangle(
        [phone_x - 6, phone_y - 6, phone_x + target_width + 6, phone_y + target_height + 6],
        radius=phone_corner_radius + 6,
        fill=(28, 38, 54, 255),
        outline=(52, 68, 92, 255),
        width=4,
    )
    canvas = Image.alpha_composite(canvas, bezel)

    # Paste Phone Screen
    canvas.alpha_composite(phone_img, (phone_x, phone_y))

    # Save Output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output_path, "PNG", optimize=True)


def create_contact_sheet(paths: list[Path], output: Path) -> None:
    thumb_w, thumb_h = 264, 574
    gap = 24
    sheet = Image.new("RGB", (gap + 5 * (thumb_w + gap), gap + 2 * (thumb_h + 62 + gap)), "#0B1522")
    draw = ImageDraw.Draw(sheet)
    label_font = get_font(FONT_SEMIBOLD_PATH, 20)
    for index, path in enumerate(paths):
        image = Image.open(path).convert("RGB")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gap + (index % 5) * (thumb_w + gap)
        y = gap + (index // 5) * (thumb_h + 62 + gap)
        sheet.paste(image, (x, y))
        draw.text((x, y + thumb_h + 12), path.stem, font=label_font, fill=WHITE)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, "PNG", optimize=True)


def main() -> None:
    plan = json.loads(PLAN_PATH.read_text())
    locale_map = {"es-ES": "es", "en-US": "en"}

    for locale, lang_key in locale_map.items():
        outputs: list[Path] = []
        print(f"\n--- Generating {locale} screenshots ---")
        for scene in plan["scenes"]:
            order = scene["order"]
            raw_file = scene.get("raw_file", f"{order:02d}.png")
            raw_path = RAW_ROOT / locale / raw_file
            if not raw_path.exists():
                raise FileNotFoundError(f"Missing raw capture: {raw_path}")

            out_filename = scene["raw_file"]
            output_path = FINAL_ROOT / locale / "iphone-69" / out_filename

            scene_data = scene[lang_key]
            compose_screenshot(raw_path, output_path, order, scene_data, locale)
            outputs.append(output_path)
            print(f"[{order:02d}/10] {out_filename}: {scene_data['action']} {scene_data['title']}")

        contact_sheet_path = REVIEW_ROOT / f"contact-{locale}.png"
        create_contact_sheet(outputs, contact_sheet_path)
        print(f"✓ Contact sheet saved: {contact_sheet_path}")


if __name__ == "__main__":
    main()

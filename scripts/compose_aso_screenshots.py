#!/usr/bin/env python3
"""Create deterministic App Store marketing screenshots from real Shield UI captures."""

from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / ".asc" / "aso-screenshot-plan.json"
RAW_ROOT = ROOT / ".asc" / "screenshots" / "aso" / "raw"
FINAL_ROOT = ROOT / ".asc" / "screenshots" / "aso" / "final"
REVIEW_ROOT = ROOT / ".asc" / "screenshots" / "aso" / "review"

WIDTH = 1320
HEIGHT = 2868
BACKGROUND = "#0B0B0F"
SURFACE = "#18181E"
ACCENT = "#FFD60A"
WHITE = "#F7F7FA"
SECONDARY = "#A7A7B2"

FONT_CANDIDATES = [
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/SFNSDisplay.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
]


def font(size: int) -> ImageFont.FreeTypeFont:
    for candidate in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(candidate, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def fit_font(draw: ImageDraw.ImageDraw, text: str, maximum: int, max_width: int) -> ImageFont.FreeTypeFont:
    size = maximum
    while size > 44:
        candidate = font(size)
        box = draw.textbbox((0, 0), text, font=candidate, stroke_width=0)
        if box[2] - box[0] <= max_width:
            return candidate
        size -= 2
    return font(size)


def rounded_image(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width, image.height), radius=radius, fill=255)
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.paste(image.convert("RGBA"), (0, 0), mask)
    return result


def compose(raw_path: Path, output_path: Path, order: int, copy: list[str], locale: str) -> None:
    verb, descriptor, supporting = copy
    canvas = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(canvas)

    # Cohesive brand accents used across the full set.
    draw.rounded_rectangle((72, 92, 258, 148), radius=28, fill=ACCENT)
    draw.text((104, 105), "SHIELD", font=font(27), fill="#101014")
    locale_label = "PRIVACIDAD EN EL DISPOSITIVO" if locale == "es-ES" else "PRIVACY ON DEVICE"
    draw.text((286, 108), locale_label, font=font(25), fill=SECONDARY)
    draw.ellipse((1110, 55, 1335, 280), outline="#2D2D35", width=5)
    draw.ellipse((1160, 105, 1285, 230), outline=ACCENT, width=5)
    draw.text((1120, 250), f"{order:02d}", font=font(38), fill="#494950")

    safe_left = 72
    safe_width = 1080
    verb_font = fit_font(draw, verb, 118, safe_width)
    descriptor_font = fit_font(draw, descriptor, 78, safe_width)
    draw.text((safe_left, 205), verb, font=verb_font, fill=ACCENT)
    verb_box = draw.textbbox((safe_left, 205), verb, font=verb_font)
    descriptor_y = verb_box[3] + 2
    draw.text((safe_left, descriptor_y), descriptor, font=descriptor_font, fill=WHITE)
    descriptor_box = draw.textbbox((safe_left, descriptor_y), descriptor, font=descriptor_font)
    supporting_y = descriptor_box[3] + 20
    support_font = fit_font(draw, supporting, 37, safe_width)
    draw.text((safe_left, supporting_y), supporting, font=support_font, fill=SECONDARY)

    # Device-like viewport: real simulator UI, rounded glass edge and bottom bleed.
    raw = Image.open(raw_path).convert("RGB")
    target_width = 1120
    target_height = round(raw.height * target_width / raw.width)
    raw = raw.resize((target_width, target_height), Image.Resampling.LANCZOS)
    phone = rounded_image(raw, 76)
    phone_x = (WIDTH - target_width) // 2
    phone_y = max(690, supporting_y + 78)

    shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (phone_x - 20, phone_y - 18, phone_x + target_width + 20, phone_y + target_height + 22),
        radius=92,
        fill=(0, 0, 0, 205),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    border = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border)
    border_draw.rounded_rectangle(
        (phone_x - 7, phone_y - 7, phone_x + target_width + 7, phone_y + target_height + 7),
        radius=84,
        fill=SURFACE,
        outline="#3A3A43",
        width=5,
    )
    canvas = Image.alpha_composite(canvas, border)
    canvas.alpha_composite(phone, (phone_x, phone_y))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output_path, "PNG", optimize=True)


def contact_sheet(paths: list[Path], output: Path) -> None:
    thumb_w, thumb_h = 264, 574
    gap = 24
    sheet = Image.new("RGB", (gap + 5 * (thumb_w + gap), gap + 2 * (thumb_h + 62 + gap)), "#202026")
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(paths):
        image = Image.open(path).convert("RGB")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gap + (index % 5) * (thumb_w + gap)
        y = gap + (index // 5) * (thumb_h + 62 + gap)
        sheet.paste(image, (x, y))
        draw.text((x, y + thumb_h + 12), path.stem, font=font(22), fill=WHITE)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, "PNG", optimize=True)


def main() -> None:
    plan = json.loads(PLAN_PATH.read_text())
    locale_keys = {"es-ES": "es", "en-US": "en"}
    for locale, copy_key in locale_keys.items():
        outputs: list[Path] = []
        for scene in plan["scenes"]:
            order = scene["order"]
            raw = RAW_ROOT / locale / f"{order:02d}-{scene['scene']}.png"
            if not raw.exists():
                raise FileNotFoundError(raw)
            output = FINAL_ROOT / locale / "iphone-69" / f"{order:02d}-{scene['scene']}.png"
            compose(raw, output, order, scene[copy_key], locale)
            outputs.append(output)
        contact_sheet(outputs, REVIEW_ROOT / f"contact-{locale}.png")
        print(f"{locale}: {len(outputs)} screenshots -> {outputs[0].parent}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate a visual contact sheet of all 10 raw screenshots in ES and EN for verification."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / ".asc" / "screenshots" / "raw_captures"
OUTPUT_DIR = ROOT / ".asc" / "screenshots" / "raw_captures" / "review"

def font(size: int) -> ImageFont.FreeTypeFont:
    for candidate in [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
    ]:
        try:
            return ImageFont.truetype(candidate, size=size)
        except OSError:
            continue
    return ImageFont.load_default()

def make_contact_sheet(locale: str) -> Path:
    locale_dir = RAW_DIR / locale
    files = sorted(locale_dir.glob("*.png"))
    if not files:
        raise FileNotFoundError(f"No PNG files in {locale_dir}")

    thumb_w, thumb_h = 240, 520
    cols = 5
    rows = 2
    gap = 20
    title_h = 60

    sheet_w = gap + cols * (thumb_w + gap)
    sheet_h = title_h + gap + rows * (thumb_h + 30 + gap)

    sheet = Image.new("RGB", (sheet_w, sheet_h), "#0E1826")
    draw = ImageDraw.Draw(sheet)

    draw.text((gap, 15), f"MaskID - Raw Captures Contact Sheet ({locale})", font=font(24), fill="#20C7D9")

    for idx, filepath in enumerate(files):
        c = idx % cols
        r = idx // cols
        x = gap + c * (thumb_w + gap)
        y = title_h + gap + r * (thumb_h + 30 + gap)

        img = Image.open(filepath).convert("RGB")
        img.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        sheet.paste(img, (x, y))

        draw.text((x, y + img.height + 6), filepath.name[:18], font=font(14), fill="#F7F7FA")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_path = OUTPUT_DIR / f"contact_sheet_{locale}.png"
    sheet.save(output_path, "PNG", optimize=True)
    return output_path

if __name__ == "__main__":
    for loc in ["es-ES", "en-US"]:
        out = make_contact_sheet(loc)
        print(f"Contact sheet saved to: {out}")

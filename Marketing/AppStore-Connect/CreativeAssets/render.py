#!/usr/bin/env python3
"""Render localized MaskID App Store creative videos from authentic app captures."""

from __future__ import annotations

import argparse
import math
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
CAPTURES = REPO / "Marketing/30-Day-Social-Campaign/source-captures"
FPS = 30
DURATION = 15
SCENE_COUNT = 4
SCENE_DURATION = DURATION / SCENE_COUNT
TRANSITION = 0.52
SCREEN_CROP = (94, 650, 1226, 2868)

INK = "#050D18"
DEEP = "#071426"
SURFACE = "#0E2038"
SURFACE_LINE = "#1B3552"
CYAN = "#20C7D9"
WHITE = "#F5F5F7"
SECONDARY = "#C0CBD9"
QUIET = "#8293A8"

FONTS = {
    "headline": "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
    "body": "/System/Library/Fonts/Avenir Next.ttc",
    "mono": "/System/Library/Fonts/Menlo.ttc",
}

COPY = {
    "en-US": {
        "topline": "MASKID  /  PRIVATE ON-DEVICE",
        "footer": "YOUR DATA. YOUR DECISION.",
        "steps": ("SCAN", "REVIEW", "EXPORT"),
        "scenes": (
            ("Your identity.\nYour call.", "Scan or import on your device."),
            ("Review each\nsuggestion.", "You choose what to hide."),
            ("Hide only what's\nsensitive.", "Adjust redactions before export."),
            ("Share a verified\ncopy.", "Check the finished file before sharing."),
        ),
    },
    "es-ES": {
        "topline": "MASKID  /  PRIVACIDAD EN EL DISPOSITIVO",
        "footer": "TUS DATOS. TU DECISIÓN.",
        "steps": ("ESCANEA", "REVISA", "EXPORTA"),
        "scenes": (
            ("Tu identidad.\nTú decides.", "Escanea o importa en el dispositivo."),
            ("Revisa cada\nsugerencia.", "Elige qué campos ocultar."),
            ("Oculta solo lo\nsensible.", "Ajusta las redacciones antes de exportar."),
            ("Revisa la copia\nantes de compartir.", "Comprueba el archivo exportado."),
        ),
    },
}

SCREENS = {
    "en-US": ("en-01-home.png", "en-04-ocr.png", "en-03-editor.png", "en-05-export.png"),
    "es-ES": ("es-01-home.png", "es-04-ocr.png", "es-03-editor.png", "es-05-export.png"),
}

FORMATS = {
    "product-page-header": (3840, 1646, "header"),
    "search-results": (2880, 1920, "search"),
}


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONTS[name], size=size, index=0)


def ease(value: float) -> float:
    value = min(1.0, max(0.0, value))
    return value * value * (3.0 - 2.0 * value)


def text_width(draw: ImageDraw.ImageDraw, text: str, selected_font: ImageFont.FreeTypeFont) -> int:
    bounds = draw.textbbox((0, 0), text, font=selected_font)
    return bounds[2] - bounds[0]


def wrap_text(text: str, selected_font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    draw = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    result: list[str] = []
    current = ""
    for word in text.split():
        candidate = f"{current} {word}".strip()
        if current and text_width(draw, candidate, selected_font) > max_width:
            result.append(current)
            current = word
        else:
            current = candidate
    if current:
        result.append(current)
    return result


def draw_tracking(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    selected_font: ImageFont.FreeTypeFont,
    fill: str,
    tracking: int = 3,
) -> None:
    x, y = xy
    for character in text:
        draw.text((x, y), character, font=selected_font, fill=fill)
        x += text_width(draw, character, selected_font) + tracking


def load_screen(locale: str, name: str) -> Image.Image:
    path = CAPTURES / name
    source = Image.open(path).convert("RGB")
    return source.crop(SCREEN_CROP)


def make_background(width: int, height: int, variant: str) -> Image.Image:
    background = Image.new("RGB", (width, height), INK)
    glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    if variant == "header":
        center = (width - 280, height // 2)
        radii = (680, 520)
    else:
        center = (90, height - 90)
        radii = (620, 420)
    for radius, alpha in zip(radii, (30, 20)):
        g.ellipse(
            (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
            outline=(32, 199, 217, alpha),
            width=5,
        )
    glow = glow.filter(ImageFilter.GaussianBlur(3))
    background = Image.alpha_composite(background.convert("RGBA"), glow).convert("RGB")

    # Quiet, asymmetric geometry echoes the app's document and masking controls.
    d = ImageDraw.Draw(background)
    if variant == "header":
        x0 = width - 1060
        d.line((x0, 90, width - 300, 90), fill=SURFACE_LINE, width=3)
        d.line((x0, height - 90, width - 300, height - 90), fill=SURFACE_LINE, width=3)
    else:
        d.line((100, height - 132, width - 100, height - 132), fill=SURFACE_LINE, width=3)
    return background


def place_phone(
    canvas: Image.Image,
    screen: Image.Image,
    x: int,
    y: int,
    height: int,
    drift: int,
    zoom: float,
) -> tuple[int, int, int, int]:
    ratio = screen.width / screen.height
    screen_h = int(height * zoom)
    screen_w = int(screen_h * ratio)
    fitted = ImageOps.fit(screen, (screen_w, screen_h), method=Image.Resampling.LANCZOS, centering=(0.5, 0.46))

    # Outer glass edge and a soft shadow keep the capture distinct from the canvas.
    outer_w = screen_w + 28
    outer_h = screen_h + 28
    px = x + drift
    py = y - (outer_h - height) // 2
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (px - 14, py + 22, px + outer_w + 14, py + outer_h + 22),
        radius=72,
        fill=(0, 0, 0, 135),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    canvas.alpha_composite(shadow)

    frame = Image.new("RGBA", (outer_w, outer_h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((0, 0, outer_w - 1, outer_h - 1), radius=68, fill=DEEP, outline=SURFACE_LINE, width=6)
    mask = Image.new("L", (screen_w, screen_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, screen_w - 1, screen_h - 1), radius=54, fill=255)
    frame.paste(fitted, (14, 14), mask)
    ImageDraw.Draw(frame).rounded_rectangle((13, 13, screen_w + 14, screen_h + 14), radius=55, outline="#21334A", width=3)
    canvas.alpha_composite(frame, (px, py))
    return px, py, outer_w, outer_h


def draw_copy(canvas: Image.Image, locale: str, scene_index: int, layout: str, width: int, height: int) -> None:
    content = COPY[locale]
    draw = ImageDraw.Draw(canvas)
    if layout == "header":
        # ASC's iPhone product-page preview crops this 21:9 video to about 1.84:1.
        # Reserve extra lateral space for its carousel and share controls.
        preview_width = min(width, int(height * (11 / 6)))
        preview_left = (width - preview_width) // 2
        left = preview_left + int(preview_width * 0.18)
        copy_width = int(preview_width * 0.40)
        top = 520
        headline_size = 220
        body_size = 68
        footer_y = height - 296
    else:
        left = 1120
        copy_width = width - left - 170
        top = 430
        headline_size = 112
        body_size = 42
        footer_y = height - 250

    mono_size = 32 if layout == "header" else 26
    body_font = font("body", body_size)
    mono = font("mono", mono_size)
    headline, body = content["scenes"][scene_index]

    draw_tracking(draw, (left, top), content["topline"], mono, CYAN, tracking=2 if layout == "header" else 1)
    title = font("headline", headline_size)
    max_line = copy_width
    lines = headline.split("\n")
    while any(text_width(draw, line, title) > max_line for line in lines) and headline_size > 72:
        headline_size -= 4
        title = font("headline", headline_size)

    title_y = top + (104 if layout == "header" else 90)
    line_height = int(headline_size * 1.14)
    for index, line in enumerate(lines):
        draw.text((left, title_y + index * line_height), line, font=title, fill=WHITE)

    body_y = title_y + line_height * len(lines) + (32 if layout == "header" else 28)
    wrapped = wrap_text(body, body_font, copy_width)
    for index, line in enumerate(wrapped):
        draw.text((left, body_y + index * int(body_size * 1.38)), line, font=body_font, fill=SECONDARY)

    accent_y = footer_y - 68
    draw.rounded_rectangle((left, accent_y, left + 110, accent_y + 9), radius=5, fill=CYAN)
    steps = content["steps"]
    active = 0 if scene_index == 0 else (2 if scene_index == 3 else 1)
    step_x = left
    for index, step in enumerate(steps):
        draw_tracking(draw, (step_x, footer_y), step, mono, CYAN if index == active else QUIET, tracking=1)
        step_x += text_width(draw, step, mono) + len(step) + 18
        if index < len(steps) - 1:
            separator = " / "
            draw.text((step_x, footer_y), separator, font=mono, fill=QUIET)
            step_x += text_width(draw, separator, mono) + 18

    # A small brand sign-off stays legible at a glance and does not compete with the app.
    brand_font = font("mono", 24 if layout == "header" else 22)
    brand_y = height - (196 if layout == "header" else 100)
    draw.text((left, brand_y), content["footer"], font=brand_font, fill=QUIET)


def make_scene(locale: str, index: int, layout: str, width: int, height: int, screens: tuple[Image.Image, ...]) -> Image.Image:
    background = make_background(width, height, layout).convert("RGBA")
    if layout == "header":
        preview_width = min(width, int(height * (11 / 6)))
        preview_left = (width - preview_width) // 2
        phone_h = 1100
        # Keep the device below the preview controls and clear of the share button.
        phone_x = preview_left + int(preview_width * 0.615)
        phone_y = 530
        text_anchor_x = phone_x
    else:
        phone_h = 1620
        phone_x = 120
        phone_y = (height - phone_h) // 2 - 10
        text_anchor_x = 1120

    drift = (-18, -5, 9, 18)[index]
    zoom = 1.0 + (0.008 if index in (1, 3) else 0.0)
    place_phone(background, screens[index], phone_x, phone_y, phone_h, drift, zoom)
    draw_copy(background, locale, index, layout, width, height)

    # Frame marker / scene count, echoing the restrained interface details in MaskID.
    if layout != "header":
        draw = ImageDraw.Draw(background)
        marker_x = text_anchor_x - 90
        marker_y = height - 180
        draw.ellipse((marker_x, marker_y, marker_x + 20, marker_y + 20), fill=CYAN)
        draw.text((marker_x + 34, marker_y - 7), f"0{index + 1}", font=font("mono", 23), fill=QUIET)
    return background.convert("RGB")


def render_one(locale: str, filename: str, width: int, height: int, layout: str, ffmpeg: str) -> Path:
    screens = tuple(load_screen(locale, name) for name in SCREENS[locale])
    scenes = tuple(make_scene(locale, i, layout, width, height, screens) for i in range(SCENE_COUNT))
    output = HERE / locale / f"{filename}.mp4"
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()

    command = [
        ffmpeg,
        "-hide_banner",
        "-loglevel",
        "error",
        "-f",
        "rawvideo",
        "-pixel_format",
        "rgb24",
        "-video_size",
        f"{width}x{height}",
        "-framerate",
        str(FPS),
        "-i",
        "-",
        "-an",
        "-frames:v",
        str(DURATION * FPS),
        "-c:v",
        "libx264",
        "-preset",
        "slow",
        "-crf",
        "18",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(output),
    ]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    assert process.stdin is not None

    base = make_background(width, height, layout)
    try:
        for frame_number in range(DURATION * FPS):
            time = frame_number / FPS
            scene_index = min(SCENE_COUNT - 1, int(time / SCENE_DURATION))
            time_in_scene = time - scene_index * SCENE_DURATION
            scene = scenes[scene_index]

            # First scene gently emerges from the ink canvas; the final fade makes the loop quiet.
            if scene_index == 0 and time_in_scene < TRANSITION:
                frame = Image.blend(base, scene, ease(time_in_scene / TRANSITION))
            elif scene_index < SCENE_COUNT - 1 and time_in_scene > SCENE_DURATION - TRANSITION:
                progress = ease((time_in_scene - (SCENE_DURATION - TRANSITION)) / TRANSITION)
                frame = Image.blend(scene, scenes[scene_index + 1], progress)
            else:
                frame = scene.copy()

            if frame_number >= DURATION * FPS - int(0.6 * FPS):
                fade = 1.0 - ease((frame_number - (DURATION * FPS - int(0.6 * FPS))) / (0.6 * FPS))
                frame = Image.blend(make_background(width, height, layout), frame, fade)

            try:
                process.stdin.write(frame.tobytes())
            except BrokenPipeError:
                break
            if frame_number % FPS == 0:
                print(f"{locale} {filename}: {frame_number // FPS:02d}/{DURATION}s", file=sys.stderr)
    finally:
        process.stdin.close()
    result = process.wait()
    if result != 0:
        raise RuntimeError(f"ffmpeg exited with status {result} while rendering {output}")
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locale", choices=tuple(COPY), help="Render one locale; defaults to both.")
    parser.add_argument("--placement", choices=tuple(FORMATS), help="Render one placement; defaults to both.")
    parser.add_argument("--ffmpeg", default=shutil.which("ffmpeg"), help="Path to FFmpeg with libx264.")
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error("FFmpeg was not found. Pass --ffmpeg with the executable path.")

    locales = (args.locale,) if args.locale else tuple(COPY)
    placements = (args.placement,) if args.placement else tuple(FORMATS)
    for locale in locales:
        for placement in placements:
            width, height, layout = FORMATS[placement]
            output = render_one(locale, placement, width, height, layout, args.ffmpeg)
            print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

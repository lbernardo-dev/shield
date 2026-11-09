#!/usr/bin/env python3
"""Compose localized App Store creatives from the authenticated 1.1.7 UI captures.

The source UI is not recreated or edited. Only typography, framing, color fields,
and editorial callouts are composed around authentic screenshots captured with
MaskID Original selected and seasonal themes disabled.
"""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "Docs/release-cycle/04_RELEASE/11_SCREENSHOTS_AND_PREVIEWS"
SOURCE = BASE / "final/1.1.7"
OUTPUT = BASE / "creatives/1.1.7"

COLORS = {
    "navy_top": (5, 13, 28),
    "navy_bottom": (9, 31, 52),
    "cyan": (40, 218, 228),
    "white": (250, 252, 255),
    "body": (194, 211, 225),
    "border": (48, 78, 101),
    "amber": (255, 190, 72),
    "mint": (112, 233, 188),
}
FONT_HEAVY = "/Library/Fonts/SF-Pro-Display-Heavy.otf"
FONT_BOLD = "/Library/Fonts/SF-Pro-Display-Bold.otf"
FONT_SEMIBOLD = "/Library/Fonts/SF-Pro-Text-Semibold.otf"
FONT_MEDIUM = "/Library/Fonts/SF-Pro-Text-Medium.otf"

CREATIVES: dict[str, list[dict[str, str]]] = {
    "es-ES": [
        {"file": "01-documento-antes-de-compartir.png", "scene": "editor", "badge": "CONTROL DE TUS DOCUMENTOS", "action": "PREPARA", "title": "TU DOCUMENTO", "subtitle": "Oculta lo que no quieres compartir.", "callout": "TÚ ELIGES QUÉ QUEDA VISIBLE", "accent": "cyan"},
        {"file": "02-escanea-y-ajusta.png", "scene": "scan-review", "badge": "ESCÁNER DE DOCUMENTOS", "action": "ESCANEA Y", "title": "AJUSTA EL ENCUADRE", "subtitle": "Corrige la captura antes de empezar a editar.", "callout": "AJUSTE ANTES DEL EDITOR", "accent": "mint"},
        {"file": "03-sugerencias-ocr.png", "scene": "editor", "badge": "RECONOCIMIENTO OCR", "action": "OCR SUGIERE.", "title": "TÚ DECIDES.", "subtitle": "Revisa los campos y ajusta cada máscara.", "callout": "SUGERENCIAS REVISABLES", "accent": "cyan"},
        {"file": "04-estilos-de-mascara.png", "scene": "editor", "badge": "AJUSTES A TU MEDIDA", "action": "ELIGE QUÉ", "title": "QUIERES OCULTAR", "subtitle": "Usa máscara sólida, pixelado o desenfoque.", "callout": "SÓLIDA · PIXELADO · DESENFOQUE", "accent": "mint"},
        {"file": "05-revisa-cada-pagina.png", "scene": "editor", "badge": "REVISIÓN POR PÁGINA", "action": "REVISA TODAS", "title": "LAS PÁGINAS", "subtitle": "Comprueba el documento antes de exportar.", "callout": "PÁGINA 1 / 2 · SIGUIENTE PÁGINA", "accent": "amber"},
        {"file": "06-exporta-pdf-o-imagen.png", "scene": "export", "badge": "FORMATOS DE EXPORTACIÓN", "action": "EXPORTA EN", "title": "PDF O IMAGEN", "subtitle": "Crea una copia rasterizada para compartir.", "callout": "PDF  ·  IMAGEN", "accent": "cyan"},
        {"file": "07-comprueba-la-copia.png", "scene": "export", "badge": "COMPROBACIÓN DE EXPORTACIÓN", "action": "COMPRUEBA LA", "title": "COPIA EXPORTADA", "subtitle": "La revisión ayuda; revisa cada página por tu cuenta.", "callout": "REVISA ANTES DE COMPARTIR", "accent": "amber"},
        {"file": "08-procesamiento-en-dispositivo.png", "scene": "editor", "badge": "PROCESAMIENTO LOCAL", "action": "OCR Y REDACCIÓN", "title": "EN EL DISPOSITIVO", "subtitle": "El reconocimiento y la redacción se procesan en el dispositivo.", "callout": "SIN CUENTA MASKID PARA EL FLUJO PRINCIPAL", "accent": "mint"},
        {"file": "09-boveda-local-face-id-pin.png", "scene": "vault", "badge": "BÓVEDA LOCAL", "action": "TUS DOCUMENTOS", "title": "EN EL DISPOSITIVO", "subtitle": "Acceso con Face ID o PIN.", "callout": "FACE ID  ·  PIN", "accent": "cyan"},
        {"file": "10-organiza-tus-copias.png", "scene": "vault", "badge": "DOCUMENTOS A MANO", "action": "ORGANIZA TUS", "title": "COPIAS EN LA BÓVEDA", "subtitle": "Vuelve a los documentos que guardas en tu Bóveda.", "callout": "BÓVEDA CIFRADA · SOLO EN EL DISPOSITIVO", "accent": "mint"},
    ],
    "en-US": [
        {"file": "01-document-before-sharing.png", "scene": "editor", "badge": "DOCUMENT CONTROL", "action": "PREPARE", "title": "YOUR DOCUMENT", "subtitle": "Hide what you don’t want to share.", "callout": "YOU CHOOSE WHAT STAYS VISIBLE", "accent": "cyan"},
        {"file": "02-scan-and-refine.png", "scene": "scan-review", "badge": "DOCUMENT SCANNER", "action": "SCAN &", "title": "REFINE THE FRAME", "subtitle": "Adjust the capture before editing.", "callout": "REFINE BEFORE THE EDITOR", "accent": "mint"},
        {"file": "03-review-ocr-suggestions.png", "scene": "editor", "badge": "TEXT RECOGNITION", "action": "OCR SUGGESTS.", "title": "YOU DECIDE.", "subtitle": "Review suggested fields and adjust each mask.", "callout": "SUGGESTIONS YOU CAN REVIEW", "accent": "cyan"},
        {"file": "04-choose-mask-style.png", "scene": "editor", "badge": "FLEXIBLE EDITING", "action": "CHOOSE WHAT", "title": "TO HIDE", "subtitle": "Use solid, pixelated or blurred masks.", "callout": "SOLID · PIXELATE · BLUR", "accent": "mint"},
        {"file": "05-review-every-page.png", "scene": "editor", "badge": "PAGE-BY-PAGE REVIEW", "action": "REVIEW EVERY", "title": "PAGE", "subtitle": "Check the document before exporting.", "callout": "PAGE 1 / 2 · NEXT PAGE", "accent": "amber"},
        {"file": "06-export-pdf-or-image.png", "scene": "export", "badge": "EXPORT FORMATS", "action": "EXPORT AS", "title": "PDF OR IMAGE", "subtitle": "Create a rasterized copy to share.", "callout": "PDF  ·  IMAGE", "accent": "cyan"},
        {"file": "07-check-exported-copy.png", "scene": "export", "badge": "EXPORT CHECK", "action": "CHECK THE", "title": "EXPORTED COPY", "subtitle": "Checks help; review every page yourself.", "callout": "REVIEW BEFORE SHARING", "accent": "amber"},
        {"file": "08-on-device-processing.png", "scene": "editor", "badge": "ON-DEVICE PROCESSING", "action": "OCR & REDACTION", "title": "ON YOUR DEVICE", "subtitle": "Text recognition and redaction run on-device.", "callout": "CORE WORKFLOW NEEDS NO MASKID ACCOUNT", "accent": "mint"},
        {"file": "09-local-vault-face-id-pin.png", "scene": "vault", "badge": "ON-DEVICE VAULT", "action": "YOUR DOCUMENTS", "title": "STAY ON DEVICE", "subtitle": "Access with Face ID or a PIN.", "callout": "FACE ID  ·  PIN", "accent": "cyan"},
        {"file": "10-organize-protected-copies.png", "scene": "vault", "badge": "DOCUMENTS AT HAND", "action": "ORGANIZE YOUR", "title": "VAULT COPIES", "subtitle": "Return to documents you save in your Vault.", "callout": "ENCRYPTED VAULT · ON DEVICE ONLY", "accent": "mint"},
    ],
}

SCENES = {
    "en-US": {
        "scan-review": "01-review-scan.png",
        "editor": "02-redact-in-editor.png",
        "export": "03-check-export.png",
        "vault": "04-private-vault.png",
    },
    "es-ES": {
        "scan-review": "01-review-scan.png",
        "editor": "02-ocultar-datos.png",
        "export": "03-comprobar-exportacion.png",
        "vault": "04-boveda-privada.png",
    },
}
DEVICE_SIZES = {
    "iphone-6.9": (1320, 2868, 990, 640, 80),
    "ipad-13": (2064, 2752, 1650, 472, 112),
}


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        for candidate in ("/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"):
            try:
                return ImageFont.truetype(candidate, size=size)
            except OSError:
                pass
        return ImageFont.load_default()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def text_size(draw: ImageDraw.ImageDraw, value: str, face: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), value, font=face)
    return box[2] - box[0], box[3] - box[1]


def wrap(draw: ImageDraw.ImageDraw, value: str, face: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    result: list[str] = []
    current = ""
    for word in value.split():
        candidate = f"{current} {word}".strip()
        if current and text_size(draw, candidate, face)[0] > max_width:
            result.append(current)
            current = word
        else:
            current = candidate
    if current:
        result.append(current)
    return result


def add_gradient(width: int, height: int, accent: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(round(COLORS["navy_top"][i] * (1 - t) + COLORS["navy_bottom"][i] * t) for i in range(3))
        draw.line((0, y, width, y), fill=(*color, 255))

    # Soft brand halo adds depth while keeping the headline area uncluttered.
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = width // 2, int(height * 0.47)
    radius = min(width, height) // 3
    gd.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(*accent, 35))
    image = Image.alpha_composite(image, glow.filter(ImageFilter.GaussianBlur(max(30, width // 17))))
    od = ImageDraw.Draw(image)
    od.line((int(width * .08), int(height * .23), int(width * .22), int(height * .23)), fill=(*accent, 110), width=4)
    return image


def rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width, image.height), radius=radius, fill=255)
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.paste(image.convert("RGBA"), (0, 0), mask)
    return result


def compose(device: str, locale: str, index: int, item: dict[str, str]) -> tuple[Path, Path]:
    width, height, screen_width, screen_y, headline_size = DEVICE_SIZES[device]
    accent = COLORS[item["accent"]]
    canvas = add_gradient(width, height, accent)
    draw = ImageDraw.Draw(canvas)

    # Editorial series header, not part of the app UI.
    small = font(FONT_SEMIBOLD, 27 if device == "iphone-6.9" else 34)
    micro = font(FONT_MEDIUM, 22 if device == "iphone-6.9" else 28)
    header_text = "MASKID  /  DOCUMENT PRIVACY" if locale == "en-US" else "MASKID  /  PRIVACIDAD DOCUMENTAL"
    draw.text((72, 48), header_text, font=small, fill=COLORS["body"])
    sequence = f"{index:02d} / 10"
    seq_w, seq_h = text_size(draw, sequence, small)
    draw.rounded_rectangle((width - 72 - seq_w - 34, 38, width - 72, 38 + seq_h + 28), radius=25,
                           fill=(13, 30, 48, 255), outline=accent, width=2)
    draw.text((width - 72 - seq_w - 17, 50), sequence, font=small, fill=accent)

    badge_face = font(FONT_SEMIBOLD, 23 if device == "iphone-6.9" else 30)
    badge_w, badge_h = text_size(draw, item["badge"], badge_face)
    pill_y = 110 if device == "iphone-6.9" else 120
    pad_x, pad_y = (28, 13) if device == "iphone-6.9" else (34, 16)
    pill_w, pill_h = badge_w + 2 * pad_x, badge_h + 2 * pad_y
    pill_x = (width - pill_w) // 2
    draw.rounded_rectangle((pill_x, pill_y, pill_x + pill_w, pill_y + pill_h), radius=pill_h // 2,
                           fill=(13, 30, 48, 255), outline=accent, width=2)
    draw.text((pill_x + pad_x, pill_y + pad_y - 2), item["badge"], font=badge_face, fill=accent)

    action_face = font(FONT_HEAVY, headline_size)
    title_face = font(FONT_BOLD, headline_size - 5)
    max_text_width = width - (170 if device == "iphone-6.9" else 220)
    action_lines = wrap(draw, item["action"], action_face, max_text_width)
    title_lines = wrap(draw, item["title"], title_face, max_text_width)
    if len(action_lines) > 2 or len(title_lines) > 2:
        raise ValueError(f"Headline exceeds two lines: {locale}/{index} {item}")
    cursor_y = pill_y + pill_h + (25 if device == "iphone-6.9" else 32)
    line_gap = int(headline_size * 1.12)
    for line in action_lines:
        line_w, _ = text_size(draw, line, action_face)
        draw.text(((width - line_w) // 2, cursor_y), line, font=action_face, fill=accent)
        cursor_y += line_gap
    for line in title_lines:
        line_w, _ = text_size(draw, line, title_face)
        draw.text(((width - line_w) // 2, cursor_y), line, font=title_face, fill=COLORS["white"])
        cursor_y += line_gap

    subtitle_face = font(FONT_MEDIUM, 31 if device == "iphone-6.9" else 43)
    subtitle_lines = wrap(draw, item["subtitle"], subtitle_face, width - (180 if device == "iphone-6.9" else 260))
    subtitle_line_h = 42 if device == "iphone-6.9" else 56
    cursor_y += 2
    for line in subtitle_lines:
        line_w, _ = text_size(draw, line, subtitle_face)
        draw.text(((width - line_w) // 2, cursor_y), line, font=subtitle_face, fill=COLORS["body"])
        cursor_y += subtitle_line_h

    # A strong feature label ties each creative to a concrete, visible benefit.
    callout_face = font(FONT_SEMIBOLD, 20 if device == "iphone-6.9" else 27)
    callout_w, callout_h = text_size(draw, item["callout"], callout_face)
    max_callout = width - (120 if device == "iphone-6.9" else 180)
    if callout_w > max_callout:
        callout_face = font(FONT_SEMIBOLD, 17 if device == "iphone-6.9" else 23)
        callout_w, callout_h = text_size(draw, item["callout"], callout_face)
    callout_pad = 26 if device == "iphone-6.9" else 32
    callout_x = (width - callout_w - callout_pad * 2) // 2
    callout_y = cursor_y + (8 if device == "iphone-6.9" else 10)
    callout_h_box = callout_h + (18 if device == "iphone-6.9" else 22)
    draw.rounded_rectangle((callout_x, callout_y, callout_x + callout_w + callout_pad * 2, callout_y + callout_h_box),
                           radius=callout_h_box // 2, fill=(13, 30, 48, 255), outline=accent, width=2)
    draw.text((callout_x + callout_pad, callout_y + (9 if device == "iphone-6.9" else 10)), item["callout"], font=callout_face, fill=accent)

    # Screenshot is a pixel-preserving UI source, only scaled and clipped by the frame.
    scene_file = SCENES[locale][item["scene"]]
    source = SOURCE / device / locale / scene_file
    if not source.exists():
        raise FileNotFoundError(source)
    screenshot = Image.open(source).convert("RGB")
    screen_height = round(screen_width * screenshot.height / screenshot.width)
    max_bottom = height - (24 if device == "iphone-6.9" else 30)
    available = max_bottom - screen_y
    if screen_height > available:
        screen_width = int(available * screenshot.width / screenshot.height)
        screen_height = round(screen_width * screenshot.height / screenshot.width)
    screenshot = screenshot.resize((screen_width, screen_height), Image.Resampling.LANCZOS)
    corner = 48 if device == "iphone-6.9" else 42
    screen = rounded(screenshot, corner)
    screen_x = (width - screen_width) // 2

    # Device-card shadow and bezel create a designed showcase while preserving the source UI.
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((screen_x - 15, screen_y + 18, screen_x + screen_width + 15, screen_y + screen_height + 30),
                         radius=corner + 18, fill=(0, 0, 0, 200))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(30 if device == "iphone-6.9" else 38)))
    frame = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((screen_x - 7, screen_y - 7, screen_x + screen_width + 7, screen_y + screen_height + 7),
                         radius=corner + 7, fill=(23, 36, 53, 255), outline=COLORS["border"], width=4)
    canvas = Image.alpha_composite(canvas, frame)
    canvas.alpha_composite(screen, (screen_x, screen_y))

    out = OUTPUT / device / locale / item["file"]
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, "PNG", optimize=True)
    return out, source


def contact_sheet(paths: list[Path], output: Path, device: str) -> None:
    thumb = (264, 574) if device == "iphone-6.9" else (516, 688)
    cols = 5 if device == "iphone-6.9" else 2
    gap = 22
    rows = math.ceil(len(paths) / cols)
    label_h = 42
    sheet = Image.new("RGB", (gap + cols * (thumb[0] + gap), gap + rows * (thumb[1] + label_h + gap)), "#081322")
    draw = ImageDraw.Draw(sheet)
    face = font(FONT_SEMIBOLD, 18 if device == "iphone-6.9" else 22)
    for n, path in enumerate(paths):
        image = Image.open(path).convert("RGB")
        image.thumbnail(thumb, Image.Resampling.LANCZOS)
        x = gap + (n % cols) * (thumb[0] + gap)
        y = gap + (n // cols) * (thumb[1] + label_h + gap)
        sheet.paste(image, (x, y))
        draw.text((x, y + thumb[1] + 8), f"{n + 1:02d}  {path.stem[:26]}", font=face, fill=COLORS["white"])
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, "PNG", optimize=True)


def main() -> None:
    manifest: dict[str, Any] = {
        "version": "1.1.7",
        "build": "1172026110801",
        "baseTheme": "MaskID Original",
        "seasonalTheme": "disabled / Never use seasonal themes",
        "sourceUi": "Authentic iOS Simulator UI screenshots from the 1.1.7 release build; synthetic fixture documents.",
        "composition": "Editorial typography, color fields, framing, and feature labels added around source screenshots; app UI itself is not altered.",
        "locales": {},
    }
    review_root = OUTPUT / "review"
    for device in DEVICE_SIZES:
        manifest["locales"][device] = {}
        for locale, concepts in CREATIVES.items():
            results = []
            paths: list[Path] = []
            for index, item in enumerate(concepts, 1):
                out, source = compose(device, locale, index, item)
                paths.append(out)
                results.append({
                    "order": index,
                    "file": str(out.relative_to(BASE)),
                    "sha256": sha256(out),
                    "pixels": f"{Image.open(out).width}x{Image.open(out).height}",
                    "source": str(source.relative_to(BASE)),
                    "sourceSha256": sha256(source),
                    "headline": f"{item['action']} {item['title']}",
                    "subtitle": item["subtitle"],
                    "featureLabel": item["callout"],
                })
            contact = review_root / f"contact-{locale}-{device}.png"
            contact_sheet(paths, contact, device)
            manifest["locales"][device][locale] = results
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "CREATIVE_SET_MANIFEST.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print(f"Generated {sum(len(items) for device in manifest['locales'].values() for items in device.values())} creatives in {OUTPUT}")


if __name__ == "__main__":
    main()

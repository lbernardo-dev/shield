#!/usr/bin/env python3
"""Compose the curated iPad ASO screenshots from real MaskID simulator captures."""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_ROOT = ROOT / ".asc" / "screenshots" / "maskid-ipad"
FINAL_ROOT = ROOT / ".asc" / "screenshots" / "aso" / "final-ipad"
REVIEW_ROOT = ROOT / ".asc" / "screenshots" / "aso" / "review"

WIDTH = 2064
HEIGHT = 2752
BG_TOP = (3, 7, 18)
BG_BOTTOM = (10, 27, 48)
ACCENT = (32, 199, 217)
WHITE = (255, 255, 255)
SUBTITLE = (184, 201, 223)
FRAME = (28, 38, 54)
FRAME_EDGE = (52, 68, 92)

FONT_HEAVY = "/Library/Fonts/SF-Pro-Display-Heavy.otf"
FONT_SEMIBOLD = "/Library/Fonts/SF-Pro-Text-Semibold.otf"
FONT_MEDIUM = "/Library/Fonts/SF-Pro-Text-Medium.otf"

SCENES = {
    "en-US": [
        {
            "source": "01-identity-dni.png",
            "name": "01-identity-protection.png",
            "badge": "IDENTITY PROTECTION",
            "action": "PROTECT",
            "title": "YOUR IDENTITY",
            "subtitle": "Mask sensitive personal details before sharing any file",
        },
        {
            "source": "02-passport-international.png",
            "name": "02-passport-travel.png",
            "badge": "INTERNATIONAL TRAVEL",
            "action": "PASSPORTS &",
            "title": "TRAVEL DOCS",
            "subtitle": "Hide confidential details and MRZ codes securely",
        },
        {
            "source": "03-smart-scanner.png",
            "name": "03-smart-scanner.png",
            "badge": "SMART SCANNER",
            "action": "SCAN &",
            "title": "CAPTURE",
            "subtitle": "Instantly scan and auto-crop documents with live guides",
        },
        {
            "source": "04-ai-ocr-detection.png",
            "name": "04-ai-detection.png",
            "badge": "ON-DEVICE AI",
            "action": "SMART",
            "title": "AUTO-DETECTION",
            "subtitle": "Instantly finds IDs, signatures, bank accounts and addresses",
        },
        {
            "source": "05-antifraud-watermark.png",
            "name": "05-anti-fraud-watermark.png",
            "badge": "ANTI-FRAUD SECURITY",
            "action": "PREVENT",
            "title": "IDENTITY THEFT",
            "subtitle": "Add permanent watermarks specifying the single copy purpose",
        },
        {
            "source": "06-vault-security.png",
            "name": "06-vault-security.png",
            "badge": "ENCRYPTED LOCAL VAULT",
            "action": "PROTECT",
            "title": "WITH FACE ID",
            "subtitle": "Local AES-GCM with Face ID or PIN; optional sync",
        },
        {
            "source": "07-library-dashboard.png",
            "name": "07-document-hub.png",
            "badge": "PROTECTED DOCUMENT HUB",
            "action": "MANAGE",
            "title": "YOUR FILES",
            "subtitle": "Protected-copy library with optional sync under your control",
        },
        {
            "source": "08-batch-processing.png",
            "name": "08-batch-protection.png",
            "badge": "BATCH PROCESSING",
            "action": "PROTECT",
            "title": "IN BATCHES",
            "subtitle": "Safeguard multi-page contracts and files simultaneously",
        },
        {
            "source": "09-mask-styles.png",
            "name": "09-mask-styles.png",
            "badge": "SURGICAL PRECISION",
            "action": "CHOOSE",
            "title": "MASK STYLES",
            "subtitle": "Pick from solid blackout, high-res pixelation or secure blur",
        },
        {
            "source": "10-irreversible-export.png",
            "name": "10-verified-export.png",
            "badge": "VERIFIED EXPORT",
            "action": "SHARE",
            "title": "WITH CONFIDENCE",
            "subtitle": "Flattened output, clean metadata and export checks",
        },
    ],
    "es-ES": [
        {
            "source": "01-identity-dni.png",
            "name": "01-proteccion-identidad.png",
            "badge": "PROTECCIÓN DE IDENTIDAD",
            "action": "PROTEGE",
            "title": "TU IDENTIDAD",
            "subtitle": "Enmascara datos personales antes de compartir documentos",
        },
        {
            "source": "02-passport-international.png",
            "name": "02-pasaportes-viaje.png",
            "badge": "DOCUMENTOS INTERNACIONALES",
            "action": "PASAPORTES Y",
            "title": "VIAJES",
            "subtitle": "Oculta datos sensibles y líneas MRZ en tus identificaciones",
        },
        {
            "source": "03-smart-scanner.png",
            "name": "03-escaner-inteligente.png",
            "badge": "ESCÁNER INTELIGENTE",
            "action": "DIGITALIZA Y",
            "title": "ENCUADRA",
            "subtitle": "Captura y alinea documentos con detección de bordes en vivo",
        },
        {
            "source": "04-ai-ocr-detection.png",
            "name": "04-deteccion-ia.png",
            "badge": "IA EN EL DISPOSITIVO",
            "action": "DETECCIÓN",
            "title": "INTELIGENTE",
            "subtitle": "Reconoce DNI, firmas, cuentas y direcciones al instante",
        },
        {
            "source": "05-antifraud-watermark.png",
            "name": "05-seguridad-antifraude.png",
            "badge": "SEGURIDAD ANTIFRAUDE",
            "action": "EVITA",
            "title": "EL ROBO DE DATOS",
            "subtitle": "Añade sellos indelebles con el propósito único de la copia",
        },
        {
            "source": "06-vault-security.png",
            "name": "06-boveda-segura.png",
            "badge": "BÓVEDA LOCAL CIFRADA",
            "action": "PROTEGE",
            "title": "CON FACE ID",
            "subtitle": "AES-GCM local con Face ID o PIN; sincronización opcional",
        },
        {
            "source": "07-library-dashboard.png",
            "name": "07-biblioteca-documentos.png",
            "badge": "CENTRO DE DOCUMENTOS",
            "action": "ORGANIZA",
            "title": "TUS COPIAS",
            "subtitle": "Biblioteca de copias protegidas, con sincronización opcional",
        },
        {
            "source": "08-batch-processing.png",
            "name": "08-proteccion-lotes.png",
            "badge": "EXPEDIENTES Y CONTRATOS",
            "action": "PROCESA",
            "title": "POR LOTES",
            "subtitle": "Protege expedientes enteros y múltiples documentos a la vez",
        },
        {
            "source": "09-mask-styles.png",
            "name": "09-estilos-mascara.png",
            "badge": "PRECISIÓN QUIRÚRGICA",
            "action": "ELIGE",
            "title": "TU MÁSCARA",
            "subtitle": "Censura sólida, pixelado HD o desenfoque seguro para cada zona",
        },
        {
            "source": "10-irreversible-export.png",
            "name": "10-exportacion-verificada.png",
            "badge": "EXPORTACIÓN VERIFICADA",
            "action": "COMPARTE",
            "title": "CON CONFIANZA",
            "subtitle": "Aplanado, metadatos limpios y comprobaciones al exportar",
        },
    ],
}


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", size=size)


def gradient() -> Image.Image:
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    for y in range(HEIGHT):
        t = y / float(HEIGHT)
        color = tuple(int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3))
        draw.line([(0, y), (WIDTH, y)], fill=(*color, 255))
    glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    radius = 680
    center = (WIDTH // 2, 1050)
    glow_draw.ellipse(
        [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius],
        fill=(*ACCENT, 36),
    )
    return Image.alpha_composite(image, glow.filter(ImageFilter.GaussianBlur(140)))


def rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width, image.height), radius=radius, fill=255)
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.paste(image.convert("RGBA"), (0, 0), mask)
    return result


def centered(draw: ImageDraw.ImageDraw, text: str, y: int, face: ImageFont.FreeTypeFont, fill: tuple[int, int, int]) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=face)
    width = box[2] - box[0]
    x = (WIDTH - width) // 2
    draw.text((x, y), text, font=face, fill=fill)
    return x, box[3] - box[1]


def compose(locale: str, scene: dict[str, str]) -> Path:
    canvas = gradient()
    draw = ImageDraw.Draw(canvas)

    badge_face = font(FONT_SEMIBOLD, 28)
    badge_box = draw.textbbox((0, 0), scene["badge"], font=badge_face)
    badge_w = badge_box[2] - badge_box[0] + 72
    badge_h = badge_box[3] - badge_box[1] + 28
    badge_x = (WIDTH - badge_w) // 2
    badge_y = 92
    badge_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    badge_draw = ImageDraw.Draw(badge_layer)
    badge_draw.rounded_rectangle(
        [badge_x, badge_y, badge_x + badge_w, badge_y + badge_h],
        radius=badge_h // 2,
        fill=(*ACCENT, 30),
        outline=(*ACCENT, 100),
        width=2,
    )
    canvas = Image.alpha_composite(canvas, badge_layer)
    draw = ImageDraw.Draw(canvas)
    draw.text((badge_x + 36, badge_y + 12), scene["badge"], font=badge_face, fill=ACCENT)

    action_face = font(FONT_HEAVY, 82)
    title_face = font(FONT_HEAVY, 76)
    subtitle_face = font(FONT_MEDIUM, 36)
    _, action_h = centered(draw, scene["action"], badge_y + badge_h + 30, action_face, ACCENT)
    title_y = badge_y + badge_h + 30 + action_h + 4
    _, title_h = centered(draw, scene["title"], title_y, title_face, WHITE)
    subtitle_y = title_y + title_h + 18
    centered(draw, scene["subtitle"], subtitle_y, subtitle_face, SUBTITLE)

    raw_path = RAW_ROOT / locale / scene["source"]
    raw = Image.open(raw_path).convert("RGB")
    target_width = 1720
    target_height = round(raw.height * target_width / raw.width)
    screen = rounded(raw.resize((target_width, target_height), Image.Resampling.LANCZOS), 56)
    screen_x = (WIDTH - target_width) // 2
    screen_y = 454

    shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [screen_x - 20, screen_y + 26, screen_x + target_width + 20, screen_y + target_height + 40],
        radius=72,
        fill=(0, 0, 0, 190),
    )
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(42)))

    frame_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame_layer)
    frame_draw.rounded_rectangle(
        [screen_x - 8, screen_y - 8, screen_x + target_width + 8, screen_y + target_height + 8],
        radius=64,
        fill=(*FRAME, 255),
        outline=(*FRAME_EDGE, 255),
        width=4,
    )
    canvas = Image.alpha_composite(canvas, frame_layer)
    canvas.alpha_composite(screen, (screen_x, screen_y))

    output = FINAL_ROOT / locale / "ipad-13" / scene["name"]
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output, "PNG", optimize=True)
    return output


def contact_sheet(paths: list[Path], output: Path) -> None:
    thumb_w, thumb_h = 516, 688
    gap = 28
    columns = 2
    rows = (len(paths) + columns - 1) // columns
    sheet = Image.new(
        "RGB",
        (gap + columns * (thumb_w + gap), gap + rows * (thumb_h + 42 + gap)),
        "#0B1522",
    )
    draw = ImageDraw.Draw(sheet)
    label_face = font(FONT_SEMIBOLD, 22)
    for index, path in enumerate(paths):
        image = Image.open(path).convert("RGB")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = gap + (index % columns) * (thumb_w + gap)
        y = gap + (index // columns) * (thumb_h + 42 + gap)
        sheet.paste(image, (x, y))
        draw.text((x, y + thumb_h + 12), path.parent.parent.name + "/" + path.name, font=label_face, fill=WHITE)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, "PNG", optimize=True)


def main() -> None:
    for locale, scenes in SCENES.items():
        output_dir = FINAL_ROOT / locale / "ipad-13"
        output_dir.mkdir(parents=True, exist_ok=True)
        for stale_asset in output_dir.glob("*.png"):
            stale_asset.unlink()
        outputs = [compose(locale, scene) for scene in scenes]
        contact_sheet(outputs, REVIEW_ROOT / f"contact-ipad-{locale}.png")
        print(f"{locale}: {len(outputs)} ASO iPad screenshots -> {FINAL_ROOT / locale / 'ipad-13'}")


if __name__ == "__main__":
    main()

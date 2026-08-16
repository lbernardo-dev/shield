#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"

OUTPUT_ROOT="${OUTPUT_ROOT:-.asc/screenshots/raw_captures}"
IPHONE_ID="${UI_IPHONE_ID:-$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/{print $2; exit}')}"

if [[ -z "$IPHONE_ID" ]]; then
  echo "Error: No se encontró ningún simulador iPhone disponible." >&2
  exit 1
fi

echo "Iniciando simulador iPhone UDID: $IPHONE_ID"
xcrun simctl boot "$IPHONE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$IPHONE_ID" -b

APP_PATH="build/DerivedData/CODEX/Build/Products/Debug-iphonesimulator/MaskID.app"
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/MaskID.app"
fi

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Error: MaskID.app no encontrado en DerivedData." >&2
  exit 1
fi

echo "Instalando app desde: $APP_PATH"
xcrun simctl install "$IPHONE_ID" "$APP_PATH"

SCENES=(
  "01-editor-protected"
  "02-editor-manipulating-mask"
  "03-watermark-config"
  "04-ocr-results"
  "05-library"
  "06-export-verification"
  "07-exif-gps"
  "08-multipage-pdf"
  "09-templates"
  "10-vault-security"
)

LOCALES=(
  "es:es-ES"
  "en:en-US"
)

xcrun simctl ui "$IPHONE_ID" appearance dark

for item in "${LOCALES[@]}"; do
  lang_code="${item%%:*}"
  locale_dir="${item##*:}"
  dir="$OUTPUT_ROOT/$locale_dir"
  mkdir -p "$dir"

  echo "=== Capturando 10 escenas para $locale_dir ==="
  for scene in "${SCENES[@]}"; do
    output_file="$dir/$scene.png"
    echo "Capturando $scene ($lang_code)..."
    xcrun simctl launch --terminate-running-process "$IPHONE_ID" com.romerodev.shield \
      -ui-testing -aso-screenshots \
      -aso-language "$lang_code" \
      -aso-color-scheme dark \
      -aso-scene "$scene" >/dev/null
    
    # Pausa para permitir el renderizado de la UI y apertura de hojas (sheets)
    sleep 1.5
    xcrun simctl io "$IPHONE_ID" screenshot "$output_file" >/dev/null
    echo "  -> Guardado: $output_file ($(du -h "$output_file" | cut -f1))"
  done
done

echo ""
echo "✅ Captura completada con éxito. Se generaron las 20 capturas brutas en:"
echo "   $OUTPUT_ROOT"

#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"

OUTPUT_ROOT="${OUTPUT_ROOT:-.asc/screenshots/raw_captures}"
CAPTURE_DELAY="${ASO_CAPTURE_DELAY:-5}"
if [[ -n "${UI_IPHONE_ID:-}" ]]; then
  IPHONE_ID="$UI_IPHONE_ID"
else
  # Prefer a stable, already-supported iPhone model so another booted
  # simulator belonging to an unrelated project is not selected accidentally.
  SIM_DESTINATION="$(scripts/resolve_sim_destination.sh --sim-name "${SIM_NAME:-iPhone Air}")"
  IPHONE_ID="${SIM_DESTINATION##*=}"
fi

if [[ -z "$IPHONE_ID" ]]; then
  echo "Error: No se encontró ningún simulador iPhone disponible." >&2
  exit 1
fi

echo "Iniciando simulador iPhone UDID: $IPHONE_ID"
xcrun simctl boot "$IPHONE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$IPHONE_ID" -b

APP_PATH="/tmp/DerivedData-MaskID/CODEX/Build/Products/Debug-iphonesimulator/MaskID.app"
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="build/DerivedData/CODEX/Build/Products/Debug-iphonesimulator/MaskID.app"
fi
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
  "01-identity-dni"
  "02-passport-international"
  "03-smart-scanner"
  "04-ai-ocr-detection"
  "05-antifraud-watermark"
  "06-vault-security"
  "07-library-dashboard"
  "08-batch-processing"
  "09-mask-styles"
  "10-irreversible-export"
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
    xcrun simctl terminate "$IPHONE_ID" com.romerodev.shield >/dev/null 2>&1 || true
    launch_output="$(xcrun simctl launch --terminate-running-process "$IPHONE_ID" com.romerodev.shield \
      -ui-testing -aso-screenshots \
      -aso-language "$lang_code" \
      -aso-color-scheme dark \
      -aso-scene "$scene")"
    if [[ "$launch_output" != com.romerodev.shield:* ]]; then
      echo "Error: MaskID no confirmó el lanzamiento de $scene: $launch_output" >&2
      exit 1
    fi
    
    # Pausa para permitir el renderizado de la UI y apertura de hojas (sheets).
    # OCR/export pueden tardar más en crear sus superficies de pantalla.
    sleep "$CAPTURE_DELAY"
    tmp_shot="/tmp/simctl_shot_$$.png"
    captured=0
    for attempt in 1 2 3; do
      if xcrun simctl io "$IPHONE_ID" screenshot "$tmp_shot" >/dev/null 2>&1 && [[ -s "$tmp_shot" ]]; then
        captured=1
        break
      fi
      sleep 2
    done
    if [[ "$captured" -ne 1 ]]; then
      echo "Error: No se pudo capturar $scene tras 3 intentos." >&2
      exit 1
    fi
    # /tmp and the repository may be on different volumes; copy avoids the
    # ownership warning emitted by mv while preserving the exact PNG bytes.
    cp "$tmp_shot" "$output_file"
    rm -f "$tmp_shot"
    echo "  -> Guardado: $output_file ($(du -h "$output_file" | cut -f1))"
  done
done

echo ""
echo "✅ Captura completada con éxito. Se generaron las 20 capturas brutas en:"
echo "   $OUTPUT_ROOT"

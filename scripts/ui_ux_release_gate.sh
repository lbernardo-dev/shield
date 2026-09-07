#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"

MODE="${1:-all}"
OUTPUT_ROOT="${UI_GATE_OUTPUT:-build/ui-ux-release-gate}"
UI_GATE_AGENT_NAME="${UI_GATE_AGENT_NAME:-UI-GATE}"
PACKAGE_CACHE="${UI_GATE_PACKAGE_CACHE:-build/cache/${UI_GATE_AGENT_NAME}/swiftpm/SourcePackages}"
IPHONE_ID="${UI_IPHONE_ID:-$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $(NF-1)); print $(NF-1); exit}')}"
IPAD_ID="${UI_IPAD_ID:-$(xcrun simctl list devices available | awk -F '[()]' '/iPad/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $(NF-1)); print $(NF-1); exit}')}"
SELECTED_TESTS=(
  testHomeAccessibilityInEnglishAndSpanish
  testOnboardingAccessibilityInEnglishAndSpanish
  testLockAccessibilityInEnglishAndSpanish
  testCaptureAccessibilityInEnglishAndSpanish
  testGalleryAccessibilityInEnglishAndSpanish
  testEditorAccessibilityInEnglishAndSpanish
  testOCRAccessibilityInEnglishAndSpanish
  testExportAccessibilityInEnglishAndSpanish
  testVaultAccessibilityInEnglishAndSpanish
  testSettingsAccessibilityInEnglishAndSpanish
  testPaywallAccessibilityInEnglishAndSpanish
  testPersistentChromeAtAX5WithReducedMotion
)

usage() {
  print "Usage: scripts/ui_ux_release_gate.sh [all|test|capture]"
  print "Optional: UI_IPHONE_ID, UI_IPAD_ID, UI_GATE_OUTPUT"
}

if [[ "$MODE" != "all" && "$MODE" != "test" && "$MODE" != "capture" ]]; then
  usage
  exit 2
fi

if [[ -z "$IPHONE_ID" || -z "$IPAD_ID" ]]; then
  print "UI/UX gate requires one available iPhone and one available iPad simulator."
  exit 1
fi

mkdir -p "$OUTPUT_ROOT"
xcrun simctl boot "$IPHONE_ID" 2>/dev/null || true
xcrun simctl boot "$IPAD_ID" 2>/dev/null || true
xcrun simctl bootstatus "$IPHONE_ID" -b
xcrun simctl bootstatus "$IPAD_ID" -b

run_tests() {
  local device_id="$1"
  local label="$2"
  local derived="${UI_GATE_DERIVED_BASE:-/tmp/DerivedData-MaskID/UI-GATE}-${label:u}"
  local result="$OUTPUT_ROOT/${label}.xcresult"
  local args=()

  rm -rf "$result"
  for test_name in "${SELECTED_TESTS[@]}"; do
    args+=("-only-testing:ShieldUITests/ShieldLaunchTests/$test_name")
  done

  xcodebuild \
    -project Shield.xcodeproj \
    -scheme Shield \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$device_id" \
    -derivedDataPath "$derived" \
    -clonedSourcePackagesDirPath "$PACKAGE_CACHE" \
    -resultBundlePath "$result" \
    SWIFT_STRICT_CONCURRENCY=complete \
    -parallel-testing-enabled NO \
    "${args[@]}" \
    test
}

capture_matrix() {
  local device_id="$1"
  local label="$2"
  shift 2
  local scenes=("$@")

  for scheme in dark light; do
    xcrun simctl ui "$device_id" appearance "$scheme"
    for language in es en; do
      for scene in "${scenes[@]}"; do
        local directory="$OUTPUT_ROOT/screenshots/$label/$scheme/$language"
        mkdir -p "$directory"
        xcrun simctl launch --terminate-running-process "$device_id" com.romerodev.shield \
          -ui-testing -aso-screenshots \
          -aso-language "$language" \
          -aso-color-scheme "$scheme" \
          -aso-scene "$scene" >/dev/null
        sleep 1
        xcrun simctl io "$device_id" screenshot "$directory/$scene.png" >/dev/null
      done
    done
  done
}

if [[ "$MODE" == "all" || "$MODE" == "test" ]]; then
  AGENT_NAME="$UI_GATE_AGENT_NAME" make build
  run_tests "$IPHONE_ID" iphone
  run_tests "$IPAD_ID" ipad
fi

if [[ "$MODE" == "all" || "$MODE" == "capture" ]]; then
  if [[ "$MODE" == "capture" ]]; then
    AGENT_NAME="$UI_GATE_AGENT_NAME" make build
    APP_PATH="build/DerivedData/UI-GATE/Build/Products/Debug-iphonesimulator/MaskID.app"
    xcrun simctl install "$IPHONE_ID" "$APP_PATH"
    xcrun simctl install "$IPAD_ID" "$APP_PATH"
  fi
  capture_matrix "$IPHONE_ID" iphone home onboarding lock capture gallery editor ocr export vault settings paywall
  capture_matrix "$IPAD_ID" ipad home capture gallery editor vault settings
fi

print "UI/UX release gate passed. Artifacts: $OUTPUT_ROOT"

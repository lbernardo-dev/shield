#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/audit_ipa.sh PATH_TO_IPA"
  exit 64
fi

IPA="$1"
if [[ ! -f "$IPA" ]]; then
  echo "IPA not found: $IPA"
  exit 66
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/shield-ipa-audit.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
unzip -qq "$IPA" -d "$WORK"

APP="$WORK/Payload/Shield.app"
EXT="$APP/PlugIns/ShieldShareExtension.appex"
APP_ENTITLEMENTS="$WORK/app-entitlements.plist"
EXT_ENTITLEMENTS="$WORK/extension-entitlements.plist"

test -d "$APP"
test -d "$EXT"
test -f "$APP/PrivacyInfo.xcprivacy"
test -f "$APP/embedded.mobileprovision"
test -f "$EXT/embedded.mobileprovision"
test ! -e "$APP/Shield.storekit"

codesign --verify --deep --strict "$APP"
codesign -d --entitlements :- "$APP" > "$APP_ENTITLEMENTS" 2>/dev/null
codesign -d --entitlements :- "$EXT" > "$EXT_ENTITLEMENTS" 2>/dev/null

[[ "$(plutil -extract get-task-allow raw -o - "$APP_ENTITLEMENTS")" == "false" ]]
[[ "$(plutil -extract get-task-allow raw -o - "$EXT_ENTITLEMENTS")" == "false" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.icloud-container-environment' "$APP_ENTITLEMENTS")" == "Production" ]]
plutil -p "$APP_ENTITLEMENTS" | rg -q 'group\.com\.romerodev\.shield'
plutil -p "$APP_ENTITLEMENTS" | rg -q 'L2B56644F5\.com\.romerodev\.shield\.shared'
plutil -p "$EXT_ENTITLEMENTS" | rg -q 'group\.com\.romerodev\.shield'
plutil -p "$EXT_ENTITLEMENTS" | rg -q 'L2B56644F5\.com\.romerodev\.shield\.shared'

MINIMUM_OS="$(plutil -extract MinimumOSVersion raw -o - "$APP/Info.plist")"
[[ "$MINIMUM_OS" == "18.0" ]]

echo "Shield IPA audit passed: distribution signature, production entitlements, minimum OS and resources are valid."

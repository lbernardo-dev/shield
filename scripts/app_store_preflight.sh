#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"
MODE="${1:---local}"

plutil -lint Shield/Resources/Info.plist
plutil -lint Shield/Resources/PrivacyInfo.xcprivacy
plutil -lint Shield/Shield.entitlements
plutil -lint ShareExtension/Info.plist
plutil -lint ShareExtension/ShareExtension.entitlements

rg -q 'TARGET_SHARE_EXTENSION.*ShieldShareExtension' Shield.xcodeproj/project.pbxproj
rg -q 'group.com.romerodev.shield' Shield/Shield.entitlements ShareExtension/ShareExtension.entitlements
rg -q '<string>shield</string>' Shield/Resources/Info.plist
rg -q 'NSCameraUsageDescription' Shield.xcodeproj/project.pbxproj
rg -q 'NSPhotoLibraryUsageDescription' Shield.xcodeproj/project.pbxproj
rg -q 'NSFaceIDUsageDescription' Shield.xcodeproj/project.pbxproj
test -f Docs/legal/privacy.html
test -f Docs/legal/terms.html
test -f Docs/legal/subscription-terms.html

if rg -n -i 'publication draft|final legal|to be completed|por completar|\bpendientes?\b|\[[^]]*(address|domicilio|provider|proveedor|legal)[^]]*\]' Docs/legal; then
  echo "App Store preflight blocked: legal documents contain draft markers or placeholders."
  exit 1
fi

if rg -n 'aps-environment|NSAllowsArbitraryLoads|custom-purchase-link|itms-apps://itunes.apple.com/app/id' Shield Shield.xcodeproj/project.pbxproj; then
  echo "App Store preflight blocked: unjustified entitlement, ATS bypass, or hard-coded App Store ID."
  exit 1
fi

if rg -n 'Shield\.storekit in Resources' Shield.xcodeproj/project.pbxproj; then
  echo "App Store preflight blocked: StoreKit test configuration is copied into the production bundle."
  exit 1
fi

if rg -n 'IPHONEOS_DEPLOYMENT_TARGET = (2[6-9]|[3-9][0-9])\.' Shield.xcodeproj/project.pbxproj; then
  echo "App Store preflight blocked: deployment target excludes pre-iOS 26 devices."
  exit 1
fi

if rg -n 'print\(|debugPrint\(|NSLog\(' Shield ShareExtension --glob '*.swift'; then
  echo "App Store preflight blocked: debug console logging remains in production sources."
  exit 1
fi

if [[ "$MODE" == "--remote" ]]; then
  check_public_url() {
    local url="$1"
    local expected_host="$2"
    local expected_marker="$3"
    local body_file
    local response
    local http_status
    local effective_url
    local effective_host
    local content_type

    body_file="$(mktemp -t shield-public-url)"
    trap 'rm -f "$body_file"' EXIT
    response="$(curl -L --silent --show-error --max-time 20 \
      --output "$body_file" \
      --write-out '%{http_code}\n%{url_effective}\n%{content_type}' \
      "$url")"
    http_status="${response%%$'\n'*}"
    effective_url="$(printf '%s\n' "$response" | sed -n '2p')"
    content_type="$(printf '%s\n' "$response" | sed -n '3p')"
    effective_host="${effective_url#*://}"
    effective_host="${effective_host%%/*}"

    if [[ "$http_status" != 2* ]]; then
      echo "App Store preflight blocked: $url returned HTTP $http_status."
      exit 1
    fi
    if [[ "$effective_host" != "$expected_host" ]]; then
      echo "App Store preflight blocked: $url redirected to untrusted host $effective_host."
      exit 1
    fi
    if [[ "$content_type" != text/html* ]]; then
      echo "App Store preflight blocked: $url returned unexpected content type $content_type."
      exit 1
    fi
    if ! rg -qi 'Shield' "$body_file" || ! rg -qi "$expected_marker" "$body_file"; then
      echo "App Store preflight blocked: $url does not contain the expected Shield content."
      exit 1
    fi
    if rg -qi 'publication draft|final legal|to be completed|por completar|\bpendientes?\b' "$body_file"; then
      echo "App Store preflight blocked: $url still exposes draft or placeholder content."
      exit 1
    fi
    rm -f "$body_file"
    trap - EXIT
  }

  canonical_host="lbernardo-dev.github.io"
  check_public_url "https://$canonical_host/apps/en/case-studies/shield/" "$canonical_host" 'Protect your identity'
  check_public_url "https://$canonical_host/apps/en/case-studies/shield/support/" "$canonical_host" 'Support'
  check_public_url "https://$canonical_host/apps/en/case-studies/shield/privacy/" "$canonical_host" 'Privacy Policy'
  check_public_url "https://$canonical_host/apps/en/case-studies/shield/terms/" "$canonical_host" 'Terms of Use'
  check_public_url "https://$canonical_host/apps/en/case-studies/shield/subscriptions/" "$canonical_host" 'Subscription Terms'
  check_public_url "https://$canonical_host/apps/es/casos/shield/" "$canonical_host" 'Protege tu identidad'
  check_public_url "https://$canonical_host/apps/es/casos/shield/soporte/" "$canonical_host" 'Soporte'
  check_public_url "https://$canonical_host/apps/es/casos/shield/privacidad/" "$canonical_host" 'Política de privacidad'
  check_public_url "https://$canonical_host/apps/es/casos/shield/terminos/" "$canonical_host" 'Términos de uso'
  check_public_url "https://$canonical_host/apps/es/casos/shield/suscripciones/" "$canonical_host" 'Condiciones de suscripción'
fi

echo "Shield App Store preflight passed ($MODE)."

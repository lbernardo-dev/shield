#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"

if rg -n 'YOUR_[A-Z_]+|response_type.*token|access[_-]token[[:space:]]*[:=][[:space:]]*"' Shield --glob '*.swift'; then
  echo "Release blocked: demo credentials or implicit OAuth found."
  exit 1
fi

plutil -lint Shield/Resources/PrivacyInfo.xcprivacy
scripts/app_store_preflight.sh --local
AGENT_NAME="${AGENT_NAME:-RELEASE}" make agent-verify
if [[ "${UI_UX_GATE_MODE:-test}" != "skip" ]]; then
  scripts/ui_ux_release_gate.sh "${UI_UX_GATE_MODE:-test}"
fi
echo "Shield release gate passed."

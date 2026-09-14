#!/usr/bin/env bash
# scripts/clean.sh
# Project maintenance and cleanup script for temporary files, build artifacts, and external volume junk.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TRASH="$SCRIPT_DIR/move_to_trash.sh"

cd "$ROOT"

ALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all|--deep)
      ALL=1
      shift
      ;;
    -h|--help)
      echo "Usage: clean.sh [--all|--deep]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

echo "🧹 [MaskID] Running project hygiene cleanup..."

# 1. Clean AppleDouble files (._*) across repository, including within .git if present
echo "  -> Removing AppleDouble resource fork files (._*)..."
find . -name "._*" -delete 2>/dev/null || true

# 2. Clean macOS Finder metadata files (.DS_Store)
echo "  -> Removing .DS_Store files..."
find . -name ".DS_Store" -delete 2>/dev/null || true

# 3. Clean Python bytecode and caches
echo "  -> Removing Python cache directories and bytecode (__pycache__, *.pyc)..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true
find . -name "*.pyd" -delete 2>/dev/null || true

# 4. Clean editor/swap/temporary files
echo "  -> Removing editor swap, backup and temporary files..."
find . \( -name "*.swp" -o -name "*.swo" -o -name "*~" -o -name "*.bak" -o -name "*.tmp" -o -name "Thumbs.db" -o -name "ehthumbs.db" \) -delete 2>/dev/null || true

# 5. Run macOS native dot_clean if available
if command -v dot_clean >/dev/null 2>&1; then
  echo "  -> Running macOS dot_clean on project root..."
  dot_clean -m . 2>/dev/null || true
fi

# 6. Deep clean of build artifacts and caches if requested or default agent cleanup
trash_if_exists() {
  for target in "$@"; do
    if [[ -e "$target" || -L "$target" ]]; then
      if [[ -x "$TRASH" ]]; then
        "$TRASH" "$target" 2>/dev/null || rm -rf "$target"
      else
        rm -rf "$target"
      fi
    fi
  done
}

if [[ $ALL -eq 1 ]]; then
  echo "  -> Deep cleaning build and derived data artifacts..."
  trash_if_exists \
    build \
    DerivedData \
    .build \
    Shield.xcodeproj/build \
    .asc/video-derived-data

  # Clean /tmp candidates matching MaskID
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    trash_if_exists "$path"
  done < <(/usr/bin/find /tmp -maxdepth 1 -mindepth 1 \( -name 'MaskID-*' -o -name 'DerivedData-MaskID' \) -print 2>/dev/null || true)

  echo "Cleaned all build artifacts and caches."
else
  AGENT_NAME_VALUE="${AGENT_NAME:-}"
  if [[ -z "$AGENT_NAME_VALUE" && -x ./scripts/resolve_agent_name.sh ]]; then
    AGENT_NAME_VALUE="$(./scripts/resolve_agent_name.sh 2>/dev/null || true)"
  fi

  if [[ -n "$AGENT_NAME_VALUE" ]]; then
    trash_if_exists \
      "build/DerivedData/$AGENT_NAME_VALUE" \
      "build/logs/$AGENT_NAME_VALUE" \
      "build/cache/$AGENT_NAME_VALUE" \
      "build/tmp/$AGENT_NAME_VALUE" \
      "Shield.xcodeproj/build/cache/$AGENT_NAME_VALUE"
    echo "Cleaned build artifacts for agent: $AGENT_NAME_VALUE"
  else
    trash_if_exists \
      build/DerivedData \
      build/logs \
      build/cache \
      build/tmp \
      Shield.xcodeproj/build \
      .asc/video-derived-data
    echo "Cleaned standard build artifacts."
  fi
fi

echo "✅ [MaskID] Repository is clean and sanitized."

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TRASH_BIN="/usr/bin/trash"

usage() {
  cat <<'USAGE'
Usage:
  scripts/cleanup_temporaries.sh --dry-run
  scripts/cleanup_temporaries.sh --apply <candidate-id> [<candidate-id> ...]

Candidate IDs are printed by --dry-run. The apply mode accepts only those
explicit IDs; it never accepts paths or wildcards.
USAGE
}

candidate_path() {
  case "$1" in
    build-logs) printf '%s\n' "$ROOT/build/logs" ;;
    build-cache) printf '%s\n' "$ROOT/build/cache" ;;
    build-tmp) printf '%s\n' "$ROOT/build/tmp" ;;
    build-derived-data) printf '%s\n' "$ROOT/build/DerivedData" ;;
    build-ui-ux-release-gate) printf '%s\n' "$ROOT/build/ui-ux-release-gate" ;;
    tmp:*)
      local tmp_name="${1#tmp:}"
      [[ "$tmp_name" != */* ]] || return 1
      case "$tmp_name" in
        MaskID-*|DerivedData-MaskID) printf '/tmp/%s\n' "$tmp_name" ;;
        *) return 1 ;;
      esac
      ;;
    sidecar:*)
      local sidecar_rel="${1#sidecar:}"
      [[ -n "$sidecar_rel" && "$sidecar_rel" != /* && "$sidecar_rel" != *'..'* ]] || return 1
      case "$sidecar_rel" in
        .git/*|.asc/*|build/*) return 1 ;;
      esac
      [[ "$(/usr/bin/basename -- "$sidecar_rel")" == ._* ]] || return 1
      printf '%s/%s\n' "$ROOT" "$sidecar_rel"
      ;;
    *) return 1 ;;
  esac
}

size_for() {
  /usr/bin/du -sh -- "$1" 2>/dev/null | /usr/bin/awk '{print $1}'
}

report_candidate() {
  local id="$1"
  local path="$2"
  if [[ -e "$path" || -L "$path" ]]; then
    printf '%s\t%s\t%s\n' "$id" "$(size_for "$path")" "$path"
  fi
}

list_candidates() {
  local id
  local path
  for id in \
    build-logs \
    build-cache \
    build-tmp \
    build-derived-data \
    build-ui-ux-release-gate; do
    path="$(candidate_path "$id")"
    report_candidate "$id" "$path"
  done

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    report_candidate "tmp:$(/usr/bin/basename -- "$path")" "$path"
  done < <(/usr/bin/find /tmp -maxdepth 1 -mindepth 1 \( -name 'MaskID-*' -o -name 'DerivedData-MaskID' \) -print)

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    local sidecar_rel="${path#"$ROOT/"}"
    report_candidate "sidecar:$sidecar_rel" "$path"
  done < <(/usr/bin/find "$ROOT" -type f -name '._*' -not -path "$ROOT/.git/*" -not -path "$ROOT/.asc/*" -not -path "$ROOT/build/*" -print | /usr/bin/sort)
}

assert_no_active_tooling() {
  local active
  active="$(/bin/ps -axo pid=,command= | /usr/bin/awk '
    {
      line = tolower($0)
      if (line ~ /\/xcode\.app\/contents\/macos\/xcode/ ||
          line ~ /(^|[[:space:]\/])(xcodebuild|swiftc|simctl|xctest|swift-package|asc)([[:space:]]|$)/) print
    }
  ' || true)"
  if [[ -n "$active" ]]; then
    printf 'Refusing cleanup: active development process detected:\n%s\n' "$active" >&2
    exit 3
  fi
}

validate_candidate() {
  local id="$1"
  local path
  path="$(candidate_path "$id")" || {
    printf 'Invalid candidate ID: %s\n' "$id" >&2
    exit 2
  }
  if [[ -L "$path" ]]; then
    printf 'Refusing symlink candidate: %s (%s)\n' "$id" "$path" >&2
    exit 2
  fi
}

trash_exact() {
  local id="$1"
  local path
  path="$(candidate_path "$id")" || {
    printf 'Invalid candidate ID: %s\n' "$id" >&2
    exit 2
  }

  if [[ -L "$path" ]]; then
    printf 'Refusing symlink candidate: %s (%s)\n' "$id" "$path" >&2
    exit 2
  fi
  if [[ ! -e "$path" ]]; then
    printf 'Candidate already absent: %s (%s)\n' "$id" "$path"
    return 0
  fi

  "$TRASH_BIN" "$path"
  if [[ -e "$path" ]]; then
    printf 'Cleanup verification failed: %s (%s)\n' "$id" "$path" >&2
    exit 4
  fi
  printf 'Moved to Trash: %s (%s)\n' "$id" "$path"
}

main() {
  [[ -x "$TRASH_BIN" ]] || {
    printf 'Required reversible cleanup tool is unavailable: %s\n' "$TRASH_BIN" >&2
    exit 1
  }

  if [[ $# -eq 0 || "$1" == "--dry-run" ]]; then
    [[ $# -le 1 ]] || { usage >&2; exit 2; }
    printf 'candidate-id\tsize\texact-path\n'
    list_candidates
    exit 0
  fi

  [[ "$1" == "--apply" ]] || { usage >&2; exit 2; }
  shift
  [[ $# -gt 0 ]] || { printf 'Apply requires at least one exact candidate ID from --dry-run.\n' >&2; exit 2; }

  local id
  # Validate the complete approved set before moving any item, preventing partial cleanup.
  for id in "$@"; do
    validate_candidate "$id"
  done
  assert_no_active_tooling
  for id in "$@"; do
    trash_exact "$id"
  done
}

main "$@"

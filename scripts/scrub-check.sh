#!/usr/bin/env bash
# scrub-check.sh — publication gate: refuse a skill that still carries internal references.
#
# Usage: scripts/scrub-check.sh skills/<name>   (target may be any dir or file)
# Exit 0 = clean, 1 = internal references found.
#
# Built-in patterns are GENERIC + STRUCTURAL (they name nobody) so this script is safe to
# publish. Personal/internal NAMES live in a gitignored .scrub-deny (one extended-regex per
# line), mirroring a gitignored secret denylist — so the denylist never publishes the very
# names it exists to hide. Point elsewhere with SCRUB_DENY=/path/to/deny.
set -euo pipefail

target="${1:?usage: scrub-check.sh <skill-dir-or-file>}"
root="$(cd "$(dirname "$0")/.." && pwd)"
deny="${SCRUB_DENY:-$root/.scrub-deny}"
hits=0

scan() {
  local pat="$1" label="$2" out
  out="$(grep -rnE "$pat" "$target" 2>/dev/null || true)"
  if [ -n "$out" ]; then printf '⚠ %s\n%s\n\n' "$label" "$out"; hits=1; fi
}

# --- generic structural patterns (name nobody, so they are safe to publish) ---
# Project-specific internal directory names (a scratch dir, a channel dir, etc.) are NOT
# hardcoded here — they differ per project and would leak your layout. Put them in .scrub-deny.
scan '/(Users|home)/[A-Za-z]'     'absolute home path'
scan '\b[A-Z]{2,5}-[A-Z][0-9]+\b' 'tracking-id shape (e.g. AB-C12)'

# --- personal denylist (gitignored) ---
if [ -f "$deny" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    scan "$line" "denylist: $line"
  done < "$deny"
else
  echo "note: no denylist at $deny — personal names unchecked (see .scrub-deny.example)" >&2
fi

if [ "$hits" -ne 0 ]; then
  echo "SCRUB: internal references found in '$target' — clean before publishing." >&2
  exit 1
fi
echo "SCRUB: '$target' is clean ✓"

#!/usr/bin/env bash
# validate.sh — repo self-check, run locally before a PR and by CI (same script, no drift).
# Checks: marketplace.json structure + no duplicate/broken plugin entries; each skill's
# SKILL.md is Agent-Skills-spec-conformant (frontmatter, name == dir, valid slug, description);
# content is English-only (public repo rule); and scrub-check finds no internal references.
# Exit 0 = all pass, 1 = at least one failure. Collects all failures (does not stop at first).
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
mp="$root/.claude-plugin/marketplace.json"
fail=0
err() { echo "  ✗ $*"; fail=1; }

echo "[1] marketplace.json structure"
if ! jq empty "$mp" 2>/dev/null; then echo "  ✗ not valid JSON"; exit 1; fi
jq -e '.name and .owner.name and (.plugins | type == "array")' "$mp" >/dev/null \
  || err "missing name / owner.name / plugins[]"
dups="$(jq -r '.plugins[].name' "$mp" | sort | uniq -d)"
[ -z "$dups" ] || err "duplicate plugin names: $dups"

echo "[2] plugin skills paths resolve"
while IFS=$'\t' read -r name spath; do
  [ -n "$spath" ] || { err "$name: no skills path"; continue; }
  [ -d "$root/${spath#./}" ] || err "$name: skills path '$spath' does not exist"
done < <(jq -r '.plugins[] | [.name, (.skills[0] // "")] | @tsv' "$mp")

echo "[3] each SKILL.md is spec-conformant"
while IFS= read -r f; do
  n="$(basename "$(dirname "$f")")"
  head -1 "$f" | grep -q '^---$' || { err "$n: SKILL.md has no frontmatter"; continue; }
  fm="$(awk 'NR>1 && /^---$/{exit} NR>1{print}' "$f")"
  fn="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
  [ "$fn" = "$n" ] || err "$n: frontmatter name '$fn' != directory name"
  printf '%s' "$fn" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' \
    || err "$n: name '$fn' is not a valid slug (lowercase letters/digits/hyphens)"
  printf '%s\n' "$fm" | grep -qE '^description:[[:space:]]*\S' || err "$n: no description"
done < <(find "$root/skills" -name SKILL.md 2>/dev/null)

echo "[4] English-only (public repo rule)"
# Conservative, unambiguous German markers + any umlaut/eszett. Word-bounded to limit noise.
while IFS= read -r f; do
  de="$(grep -owiE '(und|oder|nicht|wenn|wird|weil|sondern|damit|für|über|öffne|zeigt|warum|gilt-wenn|beleg)' "$f" 2>/dev/null | sort -u | tr '\n' ' ')"
  um="$(grep -oE '[äöüßÄÖÜ]' "$f" 2>/dev/null | sort -u | tr -d '\n')"
  hit="$de$um"
  [ -z "$hit" ] || err "${f#$root/}: looks non-English (${de}${um:+umlauts: $um}) — repo is English-only"
done < <(find "$root/skills" -name '*.md' 2>/dev/null)

echo "[5] internal-reference scrub"
for sk in "$root"/skills/*/; do
  [ -d "$sk" ] || continue
  "$root/scripts/scrub-check.sh" "$sk" >/dev/null 2>&1 || err "$(basename "$sk"): scrub-check found internal references (run scripts/scrub-check.sh skills/$(basename "$sk"))"
done

echo
if [ "$fail" -eq 0 ]; then echo "✓ all checks passed"; else echo "✗ VALIDATION FAILED"; exit 1; fi

#!/usr/bin/env bash
# Tower / Living Archive — host-side audio generator.
#
# Current MiniMax CLI (`mmx`) supports music generation but not short Foley SFX.
# This script therefore uses:
#   * mmx music generate -> music / ambience MP3 placeholders
#   * scripts/generate_sfx_placeholders.mjs -> short procedural WAV SFX
#
# Usage:
#   bash tower/generate_audio.sh
#   ONLY_IDS="mus_combat_normal amb_archive_room" bash tower/generate_audio.sh
#   SKIP_EXISTING=0 bash tower/generate_audio.sh

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT_DIR/tower/audio_manifest.json"
AUDIO_ROOT="$ROOT_DIR/tower_game/audio"
MINIMAX_CMD="${MINIMAX_CMD:-mmx}"
SKIP_EXISTING="${SKIP_EXISTING:-1}"
ONLY_IDS="${ONLY_IDS:-}"

if ! command -v jq >/dev/null 2>&1; then
  echo "This script requires jq." >&2
  exit 1
fi

mkdir -p "$AUDIO_ROOT/music" "$AUDIO_ROOT/sfx" "$AUDIO_ROOT/ambience"

should_include() {
  local id="$1"
  [ -z "$ONLY_IDS" ] || grep -qw "$id" <<<"$ONLY_IDS"
}

generate_music_asset() {
  local id="$1"
  local category="$2"
  local prompt="$3"
  local out="$AUDIO_ROOT/$category/$id.mp3"
  if [ "$SKIP_EXISTING" = "1" ] && [ -f "$out" ]; then
    echo "[skip] $id"
    return 0
  fi
  if ! command -v "$MINIMAX_CMD" >/dev/null 2>&1; then
    echo "[fail] $id — mmx CLI not found; set MINIMAX_CMD=/path/to/mmx" >&2
    return 1
  fi
  echo "[mmx ] $id -> $out"
  "$MINIMAX_CMD" --timeout 900 music generate \
    --model music-2.6 \
    --instrumental \
    --format mp3 \
    --sample-rate 44100 \
    --prompt "$prompt" \
    --out "$out" \
    --non-interactive \
    --quiet
}

generated=0
failed=0
while IFS=$'\t' read -r id category kind _duration prompt; do
  should_include "$id" || continue
  case "$category" in
    music|ambience)
      if generate_music_asset "$id" "$category" "$prompt"; then
        generated=$((generated + 1))
      else
        failed=$((failed + 1))
      fi
      ;;
    sfx)
      # SFX are generated in one batch below.
      ;;
  esac
done < <(jq -r '.assets[] | [.id, .category, .kind, .duration_s, .prompt] | @tsv' "$MANIFEST")

if [ -z "$ONLY_IDS" ] || grep -qw "sfx" <<<"$ONLY_IDS"; then
  node "$ROOT_DIR/tower/scripts/generate_sfx_placeholders.mjs"
fi

echo
echo "Summary: mmx_generated=$generated failed=$failed"
echo "Output root: $AUDIO_ROOT"
exit "$failed"

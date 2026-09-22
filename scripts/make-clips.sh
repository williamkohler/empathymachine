#!/usr/bin/env bash
# Cuts a short silent web clip from every video in the source folder.
# Re-run after adding videos; output goes to clips/ next to index.html.
#
#   scripts/make-clips.sh ["/path/to/videos"]

set -euo pipefail

SRC="${1:-$HOME/Movies/Dance Videos}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/clips"
START=1      # seconds to skip at the head of each video
LENGTH=30    # seconds per clip

mkdir -p "$OUT"
rm -f "$OUT"/*.mp4

n=0
titles=()
for f in "$SRC"/*.mp4; do
  name="$(basename "$f" .mp4)"
  case "$name" in *" copy") continue ;; esac   # skip duplicate exports
  n=$((n + 1))
  id="$(printf '%02d' "$n")"
  echo "[$id] $name"
  ffmpeg -hide_banner -loglevel error -y \
    -ss "$START" -t "$LENGTH" -i "$f" \
    -vf "scale=-2:'min(720,ih)'" \
    -an -c:v libx264 -crf 27 -preset slow -pix_fmt yuv420p \
    -movflags +faststart \
    "$OUT/$id.mp4"
  titles+=("$name")
done

# list.json: [{"file":"01.mp4","title":"..."}, ...]
{
  echo "["
  for i in "${!titles[@]}"; do
    id="$(printf '%02d' "$((i + 1))")"
    t="${titles[$i]//\\/\\\\}"; t="${t//\"/\\\"}"
    sep=","; [ "$i" -eq $((${#titles[@]} - 1)) ] && sep=""
    echo "  {\"file\": \"$id.mp4\", \"title\": \"$t\"}$sep"
  done
  echo "]"
} > "$OUT/list.json"

echo "wrote $n clips to $OUT"
du -sh "$OUT"

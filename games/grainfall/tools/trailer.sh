#!/usr/bin/env bash
# Vertical 1080×1920 social trailer (TikTok / Reels / Shorts) straight from the simulation.
#   tools/trailer.sh [sim-binary] [levels-dir] [out.mp4]
# Each segment is a level's reference solution, sped up to ~6 s, with a caption; then an outro card.
set -euo pipefail
cd "$(dirname "$0")/.."
SIM=${1:-.build/release/grainfall-sim}
LEVELS=${2:-Sources/GrainfallCore/Resources/levels}
OUT=${3:-out/grainfall-trailer.mp4}
FONT=${FONT:-/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf}
TMP=out/trailer; mkdir -p "$TMP"; rm -f "$TMP"/*.mp4 "$TMP"/list.txt
SCALE=6; W=$((128 * SCALE)); H=$((240 * SCALE))
BG=0x141626

segments=(
  "1-10|Every grain is simulated"
  "2-10|Water finds a way"
  "3-10|Keep the lava out"
  "4-10|Cool lava into stone"
  "5-10|Plants grow. Fire spreads."
  "6-10|60 hand-crafted puzzles"
)
n=0
for seg in "${segments[@]}"; do
  id=${seg%%|*}; caption=${seg#*|}
  [ -f "$LEVELS/$id.json" ] || { echo "skip $id"; continue; }
  ticks=$("$SIM" trace "$id" --solve --dir "$LEVELS" --every 100000 | sed -n 's/^end t=\([0-9]*\).*/\1/p')
  stride=$(( (ticks + 179) / 180 )); [ "$stride" -lt 2 ] && stride=2
  n=$((n + 1))
  echo "segment $n: $id ($ticks ticks, stride $stride)"
  "$SIM" video "$id" --dir "$LEVELS" --scale $SCALE --stride $stride --hold 60 |
    ffmpeg -loglevel error -y -f rawvideo -pix_fmt rgba -s ${W}x${H} -r 30 -i - \
      -vf "scale=-2:1920:flags=neighbor,pad=1080:1920:(ow-iw)/2:0:color=${BG},drawbox=y=150:w=iw:h=170:color=black@0.45:t=fill,drawtext=fontfile=${FONT}:text='${caption}':fontcolor=0xF2C46D:fontsize=72:x=(w-text_w)/2:y=200" \
      -c:v libx264 -pix_fmt yuv420p -r 30 -preset medium -crf 20 "$TMP/seg$n.mp4"
  echo "file 'seg$n.mp4'" >> "$TMP/list.txt"
done

ffmpeg -loglevel error -y -f lavfi -i "color=c=${BG}:s=1080x1920:d=2.5:r=30" \
  -vf "drawtext=fontfile=${FONT}:text='GRAINFALL':fontcolor=0xF2C46D:fontsize=150:x=(w-text_w)/2:y=760,drawtext=fontfile=${FONT}:text='Dig. Pour. Solve.':fontcolor=white:fontsize=70:x=(w-text_w)/2:y=960,drawtext=fontfile=${FONT}:text='Free on the App Store':fontcolor=0xA4A6BD:fontsize=56:x=(w-text_w)/2:y=1080" \
  -c:v libx264 -pix_fmt yuv420p -preset medium -crf 20 "$TMP/outro.mp4"
echo "file 'outro.mp4'" >> "$TMP/list.txt"

ffmpeg -loglevel error -y -f concat -safe 0 -i "$TMP/list.txt" -c copy "$OUT"
echo "wrote $OUT"

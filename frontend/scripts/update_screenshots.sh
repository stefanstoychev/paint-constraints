#!/usr/bin/env bash
# Regenerates screenshots/*.png by running integration_test/app_test.dart in
# Chrome via ChromeDriver, then refreshes the screenshot gallery in the root
# README.MD (between the <!-- screenshots:start/end --> markers).
#
# Usage: scripts/update_screenshots.sh [--headless] [--readme-only]
#   --headless     run Chrome without a window
#   --readme-only  only regenerate the README gallery, skip the tests
#
# Needs chromedriver matching your Chrome version, either on PATH or pointed to
# by $CHROMEDRIVER. Download: https://googlechromelabs.github.io/chrome-for-testing/
set -euo pipefail

PORT=4444
HEADLESS_FLAG=""
README_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --headless) HEADLESS_FLAG="--headless" ;;
    --readme-only) README_ONLY=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.."

README=../README.MD
START_MARKER='<!-- screenshots:start -->'
END_MARKER='<!-- screenshots:end -->'

update_readme_gallery() {
  if ! grep -qF "$START_MARKER" "$README" || ! grep -qF "$END_MARKER" "$README"; then
    echo "Warning: screenshot markers not found in $README; gallery not updated" >&2
    return 0
  fi

  shopt -s nullglob
  local files=(screenshots/*.png)
  shopt -u nullglob
  local count=${#files[@]}
  local gallery="" name caption f i

  gallery+="<details open>"$'\n'
  gallery+="<summary>$count screenshots</summary>"$'\n\n'
  gallery+="<table>"$'\n'
  for ((i = 0; i < count; i += 2)); do
    gallery+="  <tr>"$'\n'
    for f in "${files[@]:i:2}"; do
      # 16_snap_vertices_linked.png -> "Snap vertices linked"
      name=$(basename "$f" .png)
      caption=${name#*_}
      caption=${caption//_/ }
      caption=${caption^}
      gallery+="    <td align=\"center\" width=\"50%\">"$'\n'
      gallery+="      <a href=\"frontend/$f\"><img src=\"frontend/$f\" width=\"400\" alt=\"$caption\"></a><br>"$'\n'
      gallery+="      <sub>$caption</sub>"$'\n'
      gallery+="    </td>"$'\n'
    done
    gallery+="  </tr>"$'\n'
  done
  gallery+="</table>"$'\n\n'
  gallery+="</details>"

  local tmp
  tmp=$(mktemp)
  GALLERY="$gallery" awk -v start="$START_MARKER" -v end="$END_MARKER" '
    { sub(/\r$/, "") }
    index($0, start) { print; print ENVIRON["GALLERY"]; skip = 1; next }
    index($0, end) { skip = 0 }
    !skip { print }
  ' "$README" > "$tmp"
  mv "$tmp" "$README"
  echo "README gallery updated ($count screenshots)"
}

if [[ "$README_ONLY" == 1 ]]; then
  update_readme_gallery
  exit 0
fi

chromedriver_ready() {
  curl -s "http://localhost:$PORT/status" 2>/dev/null | grep -q '"ready": *true'
}

DRIVER_PID=""
cleanup() {
  if [[ -n "$DRIVER_PID" ]]; then
    kill "$DRIVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if chromedriver_ready; then
  echo "Using chromedriver already running on port $PORT"
else
  CHROMEDRIVER="${CHROMEDRIVER:-$(command -v chromedriver || true)}"
  if [[ -z "$CHROMEDRIVER" ]]; then
    echo "chromedriver not found. Put it on PATH or set CHROMEDRIVER=/path/to/chromedriver" >&2
    echo "Download (match your Chrome version): https://googlechromelabs.github.io/chrome-for-testing/" >&2
    exit 1
  fi

  echo "Starting chromedriver on port $PORT"
  "$CHROMEDRIVER" --port="$PORT" >/dev/null 2>&1 &
  DRIVER_PID=$!

  for _ in $(seq 1 50); do
    chromedriver_ready && break
    sleep 0.2
  done
  if ! chromedriver_ready; then
    echo "chromedriver did not become ready on port $PORT" >&2
    exit 1
  fi
fi

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome \
  $HEADLESS_FLAG

echo
update_readme_gallery

echo
echo "Changed screenshots:"
git status --short screenshots/ "$README"

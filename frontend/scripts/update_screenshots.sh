#!/usr/bin/env bash
# Regenerates screenshots/*.png by running integration_test/app_test.dart in
# Chrome via ChromeDriver.
#
# Usage: scripts/update_screenshots.sh [--headless]
#
# Needs chromedriver matching your Chrome version, either on PATH or pointed to
# by $CHROMEDRIVER. Download: https://googlechromelabs.github.io/chrome-for-testing/
set -euo pipefail

PORT=4444
HEADLESS_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --headless) HEADLESS_FLAG="--headless" ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.."

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
echo "Changed screenshots:"
git status --short screenshots/

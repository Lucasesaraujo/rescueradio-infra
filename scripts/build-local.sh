#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_PATH="${1:-$(realpath "$SCRIPT_DIR/../../rescueradio-api")}"
WEB_PATH="${2:-$(realpath "$SCRIPT_DIR/../../rescueradio-web")}"

echo "Building rescueradio-api:local from $API_PATH"
docker build -t rescueradio-api:local "$API_PATH"

echo "Building rescueradio-web:local from $WEB_PATH"
docker build -t rescueradio-web:local "$WEB_PATH"

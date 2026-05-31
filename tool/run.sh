#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${OPENWEATHER_API_KEY:-}" ]]; then
  echo "OPENWEATHER_API_KEY is not set."
  echo "Usage: OPENWEATHER_API_KEY=<key> tool/run.sh [flutter run args...]"
  exit 1
fi

flutter run \
  --dart-define=OPENWEATHER_API_KEY="${OPENWEATHER_API_KEY}" \
  "$@"

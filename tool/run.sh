#!/usr/bin/env bash
set -euo pipefail

if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

if [[ -z "${OPENWEATHER_API_KEY:-}" ]]; then
  echo "OPENWEATHER_API_KEY is not set."
  echo "Create .env with: OPENWEATHER_API_KEY=<key>"
  echo "Or run: OPENWEATHER_API_KEY=<key> tool/run.sh [flutter run args...]"
  exit 1
fi

flutter run \
  --dart-define=OPENWEATHER_API_KEY="${OPENWEATHER_API_KEY}" \
  "$@"

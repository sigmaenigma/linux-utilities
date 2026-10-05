#!/usr/bin/env bash
# cup-holder.sh — Deploys your computer's built-in beverage support system.
# Usage: ./cup-holder.sh [--close | --party | --help]

set -euo pipefail

DEVICE="${CUP_HOLDER_DEVICE:-}"

find_cup_holder() {
  for d in /dev/cdrom /dev/sr0 /dev/dvd; do
    [[ -e "$d" ]] && { echo "$d"; return 0; }
  done
  return 1
}

if ! command -v eject >/dev/null 2>&1; then
  echo "☕ Cup holder firmware missing. Install it with: sudo apt install eject"
  exit 1
fi

if [[ -z "$DEVICE" ]]; then
  DEVICE="$(find_cup_holder)" || {
    echo "🚫 No cup holder detected. Your computer was clearly designed by someone who hates beverages."
    echo "   Please hold your coffee like an animal."
    exit 2
  }
fi

case "${1:-}" in
  --close)
    echo "🔒 Retracting cup holder... please remove your drink first."
    eject -t "$DEVICE"
    ;;
  --party)
    echo "🎉 Cup holder rave mode engaged."
    for _ in {1..3}; do eject "$DEVICE"; sleep 1; eject -t "$DEVICE"; sleep 1; done
    ;;
  --help|-h)
    sed -n '2,3p' "$0"
    ;;
  "")
    echo "☕ Deploying cup holder on $DEVICE..."
    eject "$DEVICE"
    echo "✅ Cup holder deployed. Max load: one (1) beverage. Not dishwasher safe."
    ;;
  *)
    echo "Unknown option: $1 (try --help)"
    exit 1
    ;;
esac

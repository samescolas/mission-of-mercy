#!/usr/bin/env bash
#
# Start the Mission of Mercy app.
#
# Use this when the app is off -- after a reboot, or if someone shut it down.
# Safe to run when it's already running: nothing is lost and nothing restarts
# unnecessarily.
#
#     ./scripts/start.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

say "Starting the app"
dc up -d

if wait_for_app; then
  report_success
else
  report_failure
  exit 1
fi

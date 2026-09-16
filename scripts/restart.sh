#!/usr/bin/env bash
#
# Restart the Mission of Mercy app.
#
# Use this when the app is running but misbehaving -- pages hanging, errors
# that don't go away. Patient data is NOT affected: it lives in the database
# volume, which restarting does not touch.
#
#     ./scripts/restart.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

say "Restarting the app"
info "Patient data is not affected by this."

# Just restart: this script is for an app that's running badly, so the
# containers already exist. Running `up -d` first would boot everything and
# then immediately cycle it again, costing an extra minute of downtime.
# If the containers are missing entirely, that's what start.sh is for.
if ! dc restart; then
  fail "Could not restart. The app may not be running at all."
  info "Try starting it instead:  ./scripts/start.sh"
  exit 1
fi

if wait_for_app; then
  report_success
else
  report_failure
  exit 1
fi

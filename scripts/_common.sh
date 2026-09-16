# Shared helpers for start.sh and restart.sh.
#
# Not meant to be run directly. Both scripts source this so they behave the
# same way and there's only one place to fix.
#
# Assumes the server has already been provisioned by provision-server.sh:
# Docker is installed and this user can run it without sudo.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.standalone.yaml"

# How long to wait for the app to answer before giving up. A cold start boots
# four unicorn workers, which takes about a minute.
WAIT_SECONDS=240

say()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[0;32mOK\033[0m  %s\n' "$*"; }
info() { printf '        %s\n' "$*"; }
fail() { printf '\n\033[0;31mPROBLEM:\033[0m %s\n\n' "$*" >&2; }

dc() { docker compose $COMPOSE_FILES "$@"; }

# The address a clinic laptop should point at.
#
# Filters by interface name rather than address range. Docker's own interfaces
# (docker0 and the br-* bridges Compose creates) all carry 172.16/12 addresses,
# which sit inside the private ranges but are unreachable from a clinic laptop.
# Matching on the range would hand out one of those whenever it happened to
# come first.
server_url() {
  local ip
  ip="$(ip -4 -o addr show scope global 2>/dev/null \
        | grep -vE '\s(docker[0-9]*|br-[0-9a-f]+|veth[0-9a-z]*)\s' \
        | awk '{print $4}' | cut -d/ -f1 | head -1)"
  # Better to say nothing than to send someone to an address that won't work.
  [ -z "$ip" ] && ip="<this-server's-ip>"
  echo "http://${ip}/"
}

# Poll nginx on port 80 until the app answers. This is the real end-to-end
# check: a response here means nginx, unicorn and Postgres are all working.
wait_for_app() {
  say "Waiting for the app to respond (up to $((WAIT_SECONDS / 60)) minutes)"
  info "A cold start takes a minute or so while the app boots."
  local waited=0
  while [ "$waited" -lt "$WAIT_SECONDS" ]; do
    if curl -fsS -o /dev/null --max-time 5 http://127.0.0.1/ 2>/dev/null; then
      printf '\n'
      return 0
    fi
    printf '.'
    sleep 5
    waited=$((waited + 5))
  done
  printf '\n'
  return 1
}

report_success() {
  say "Done"
  ok "The app is running."
  echo
  info "Open this address in the browser: $(server_url)"
  echo
}

report_failure() {
  fail "The app did not respond within $((WAIT_SECONDS / 60)) minutes."
  echo "What to try, in order:"
  echo
  echo "  1. Check which containers are running:"
  echo "       cd $REPO_ROOT && docker compose $COMPOSE_FILES ps"
  echo
  echo "  2. Look at the app's error messages:"
  echo "       cd $REPO_ROOT && docker compose $COMPOSE_FILES logs --tail 50 web"
  echo
  echo "  3. If the database looks like the problem:"
  echo "       cd $REPO_ROOT && docker compose $COMPOSE_FILES logs --tail 50 db"
  echo
  echo "Keep that output -- it's what someone technical will need."
  echo
}

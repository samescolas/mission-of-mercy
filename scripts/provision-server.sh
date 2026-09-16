#!/usr/bin/env bash
#
# Provision a blank Ubuntu server to run the Mission of Mercy clinic stack.
#
# Takes a fresh Ubuntu box to the point where you can start the app. Installs
# Docker from Docker's own apt repo, sets the clock to clinic-local time, and
# pre-builds the images so a build failure surfaces now rather than on setup
# morning.
#
# Usage, on the new server:
#
#     ./scripts/provision-server.sh              # provision and pre-build
#     ./scripts/provision-server.sh --skip-build # provision only, build later
#
# Safe to re-run; every step checks before it acts.

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/samescolas/mission-of-mercy}"
APP_DIR="${APP_DIR:-$HOME/mission-of-mercy}"
TZ_NAME="${TZ_NAME:-America/New_York}"

# docker-compose.standalone.yaml uses the !override and !reset merge tags,
# which Compose only understands from v2.24 on.
MIN_COMPOSE_MAJOR=2
MIN_COMPOSE_MINOR=24

SKIP_BUILD=0
[ "${1:-}" = "--skip-build" ] && SKIP_BUILD=1

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[0;32m|\033[0m %s\n' "$*"; }
warn() { printf '    \033[0;33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[0;31m!!\033[0m %s\n\n' "$*" >&2; exit 1; }

# Docker group membership does not take effect until the user logs back in, so
# provisioning-time docker calls usually need sudo. On a re-run, when the group
# is already active, plain docker works and sudo would just prompt for nothing.
# probe_docker() decides once, after Docker is installed.
DOCKER_SUDO="sudo"
probe_docker() {
  if docker info >/dev/null 2>&1; then
    DOCKER_SUDO=""
    ok "Running docker without sudo"
  else
    ok "Running docker via sudo (group membership is not active yet)"
  fi
}
d() { ${DOCKER_SUDO:+sudo} docker "$@"; }

# ---------------------------------------------------------------- preflight --

log "Checking the environment"

[ "$(id -u)" -eq 0 ] && die "Run as a normal user with sudo, not as root. The\
 app runs as your user, and running this as root puts the repo and Docker\
 group membership on the wrong account."

command -v sudo >/dev/null || die "sudo is not installed."
sudo -v || die "This user cannot sudo."

[ -f /etc/os-release ] || die "Cannot identify the OS; expected Ubuntu."
. /etc/os-release
[ "${ID:-}" = "ubuntu" ] || warn "Expected Ubuntu, found '${ID:-unknown}'. Continuing anyway."
ok "OS: ${PRETTY_NAME:-unknown}"
ok "User: $(whoami)"

# ------------------------------------------------------------------ packages --

log "Installing base packages"
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl gnupg git
ok "ca-certificates, curl, gnupg, git"

# No postgresql-client on the host on purpose: psql and pg_restore run inside
# the db container via `docker compose exec`, and the standalone compose file
# doesn't publish 5432, so a host client would have nothing to connect to.

# -------------------------------------------------------------------- clock --

log "Setting the timezone"
if [ "$(timedatectl show -p Timezone --value)" = "$TZ_NAME" ]; then
  ok "Already $TZ_NAME"
else
  sudo timedatectl set-timezone "$TZ_NAME"
  ok "Set to $TZ_NAME"
fi
# Containers inherit the host clock, so this is what makes check-in and
# check-out timestamps read correctly in the clinic reports.

# ------------------------------------------------------------------- docker --

log "Installing Docker"
if command -v docker >/dev/null 2>&1; then
  ok "Already installed: $(docker --version)"
else
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
                              docker-buildx-plugin docker-compose-plugin
  ok "Installed: $(docker --version)"
fi
# Docker's own repo, not Ubuntu's docker.io, because docker.io ships an older
# engine without the Compose v2 plugin this stack needs.

sudo systemctl enable --now docker >/dev/null 2>&1 || true
sudo systemctl is-active --quiet docker || die "Docker installed but not running."
ok "Docker service is running"
probe_docker

log "Checking the Compose version"
COMPOSE_VER="$(d compose version --short 2>/dev/null | sed 's/^v//')" \
  || die "The Compose plugin is missing. Install docker-compose-plugin."
COMPOSE_MAJOR="${COMPOSE_VER%%.*}"
COMPOSE_REST="${COMPOSE_VER#*.}"
COMPOSE_MINOR="${COMPOSE_REST%%.*}"
if [ "$COMPOSE_MAJOR" -lt "$MIN_COMPOSE_MAJOR" ] || \
   { [ "$COMPOSE_MAJOR" -eq "$MIN_COMPOSE_MAJOR" ] && [ "$COMPOSE_MINOR" -lt "$MIN_COMPOSE_MINOR" ]; }; then
  die "Compose $COMPOSE_VER is too old. docker-compose.standalone.yaml uses the\
 !override and !reset merge tags, added in ${MIN_COMPOSE_MAJOR}.${MIN_COMPOSE_MINOR}.\
 On an older version the port and volume overrides are silently wrong."
fi
ok "Compose $COMPOSE_VER supports the !override/!reset merge tags"

log "Adding $(whoami) to the docker group"
if id -nG "$(whoami)" | tr ' ' '\n' | grep -qx docker; then
  ok "Already a member"
else
  sudo usermod -aG docker "$(whoami)"
  ok "Added (takes effect at your next login)"
fi

# --------------------------------------------------------------------- swap --

log "Checking memory"
MEM_MB=$(free -m | awk '/^Mem:/{print $2}')
SWAP_MB=$(free -m | awk '/^Swap:/{print $2}')
ok "RAM: ${MEM_MB}MB, swap: ${SWAP_MB}MB"
if [ "$MEM_MB" -lt 4000 ] && [ "$SWAP_MB" -lt 1000 ]; then
  warn "Under 4GB RAM with no swap; adding a 2GB swapfile."
  warn "Four unicorn workers plus Postgres plus the image build can exceed this."
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile >/dev/null
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
  ok "2GB swapfile active and added to /etc/fstab"
fi

# --------------------------------------------------------------------- repo --

log "Fetching the application"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../docker-compose.standalone.yaml" ]; then
  APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  ok "Running from inside the repo: $APP_DIR"
elif [ -d "$APP_DIR/.git" ]; then
  ok "Already cloned: $APP_DIR"
else
  git clone "$REPO_URL" "$APP_DIR"
  ok "Cloned to $APP_DIR"
fi

cd "$APP_DIR"

# Only the files Compose won't catch on its own. The two compose files are
# already covered by `config -q` below, but these two are not:
#
#   standalone.conf  is a bind-mount source, and Compose does not validate
#                    those. If it's missing, `up` creates a root-owned
#                    *directory* at that path, mounts it over nginx's config,
#                    and nginx serves its default welcome page -- the stack
#                    looks healthy while the app is unreachable.
#   unicorn.docker.rb is read at container start, so a missing file means the
#                    web container crash-loops after `up` reports success.
for f in nginx/conf.d/standalone.conf config/unicorn.docker.rb; do
  [ -f "$f" ] || die "Missing $f. This checkout predates the standalone\
 deployment setup; pull the branch that has it."
done
ok "Bind-mount and unicorn config files present"

mkdir -p xray tmp/pids log
ok "Runtime directories ready"

log "Validating the Compose configuration"
d compose -f docker-compose.yaml -f docker-compose.standalone.yaml config -q \
  || die "The merged Compose config is invalid."
ok "Merged config parses"

# -------------------------------------------------------------------- build --

if [ "$SKIP_BUILD" -eq 1 ]; then
  log "Skipping the image build (--skip-build)"
  warn "The first 'up' will build instead. That compiles Ruby 2.3.8 from"
  warn "source and takes 10-20 minutes; don't discover that on clinic morning."
else
  log "Building images (10-20 minutes: Ruby 2.3.8 compiles from source)"
  d compose -f docker-compose.yaml -f docker-compose.standalone.yaml build
  ok "Images built"
fi

# --------------------------------------------------------------------- done --

COMPOSE_ARGS="-f docker-compose.yaml -f docker-compose.standalone.yaml"

cat <<EOF

$(printf '\033[1;32m')Provisioning complete.$(printf '\033[0m')

  App directory:  $APP_DIR
  Timezone:       $(timedatectl show -p Timezone --value)
  Docker:         $(docker --version | cut -d, -f1)
  Compose:        v$COMPOSE_VER

$(printf '\033[1m')Log out and back in first$(printf '\033[0m') so your docker group membership takes
effect. Without that, docker commands need sudo.

Then, from $APP_DIR:

  1. Start the stack
       docker compose $COMPOSE_ARGS up -d

  2. Restore the database dump you copied over
       docker compose $COMPOSE_ARGS exec -T db \\
         pg_restore -U mom -d rimom --no-owner --clean --if-exists < rimom-*.dump

     The -T matters; without it Docker corrupts the binary stream.

  3. Confirm it came through
       docker compose $COMPOSE_ARGS exec -T db \\
         psql -U mom -d rimom -c "SELECT count(*) FROM patients;"

  4. Open http://<this-server-ip>/ and sign in

Reminders:
  - Truncate patient data the day before the event (Admin > Maintenance >
    Reset the entire clinic database). A restored dump carries last year's
    records, and chart numbers resume where that dump left off.
  - This serves plain HTTP on port 80, which assumes the private VPN network.
    Do not expose this host to the internet as configured.
  - ufw is left alone deliberately. If you enable it, allow 22 and 80 before
    you turn it on, or you will lock yourself out.

EOF

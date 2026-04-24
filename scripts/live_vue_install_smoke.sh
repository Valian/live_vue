#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
LIVE_VUE_ROOT="${LIVE_VUE_ROOT:-$(cd -- "$SCRIPT_DIR/.." && pwd -P)}"
APP_NAME="${APP_NAME:-live_vue_smoke}"
DATABASE="${DATABASE:-sqlite3}"
TMP_PARENT="${TMP_PARENT:-${TMPDIR:-/tmp}}"
TMP_BASE="${TMP_BASE:-$TMP_PARENT/live_vue_install_smoke}"

usage() {
  cat <<EOF
Usage: $(basename "$0")

Creates a temporary Phoenix app, installs LiveVue from this checkout, builds
frontend assets, and verifies that both dev and production SSR work correctly.

Environment overrides:
  APP_NAME       Phoenix app directory/name. Default: live_vue_smoke
  DATABASE       phx.new database option. Default: sqlite3
  TMP_PARENT     Parent directory for the temporary workspace. Default: \${TMPDIR:-/tmp}
  TMP_BASE       Root directory for all smoke-test runs. Default: \$TMP_PARENT/live_vue_install_smoke
  LIVE_VUE_ROOT  LiveVue checkout to install from. Default: repository root
  PHX_NEW_ARGS   Extra arguments passed to mix phx.new
  INSTALL_ARGS   Extra arguments passed to mix igniter.install
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_command() {
  local command_name="$1"
  local install_hint="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n%s\n' "$command_name" "$install_hint" >&2
    exit 1
  fi
}

require_mix_task() {
  local task_name="$1"
  local install_hint="$2"
  local check_dir

  mkdir -p "$TMP_BASE"
  check_dir="$(mktemp -d "$TMP_BASE/mix_task_check.XXXXXX")"
  if ! (cd "$check_dir" && mix help "$task_name" >/dev/null 2>&1); then
    rm -rf "$check_dir"
    printf 'Missing required Mix task: %s\n%s\n' "$task_name" "$install_hint" >&2
    exit 1
  fi
  rm -rf "$check_dir"
}

run() {
  printf '\n==> %s\n' "$*"
  "$@"
}

require_command mix "Install Elixir and Mix first."
require_command node "Install Node.js before running this smoke test."
require_command npm "Install npm before running this smoke test."
require_command rsync "Install rsync before running this smoke test."
require_command curl "Install curl before running this smoke test."
require_command perl "Install perl before running this smoke test."
require_mix_task phx.new "Install the Phoenix project generator with: mix archive.install hex phx_new"
require_mix_task igniter.install "Install Igniter with: mix archive.install hex igniter_new"

if [[ ! -f "$LIVE_VUE_ROOT/mix.exs" || ! -f "$LIVE_VUE_ROOT/package.json" ]]; then
  printf 'LIVE_VUE_ROOT does not look like the LiveVue repository: %s\n' "$LIVE_VUE_ROOT" >&2
  exit 1
fi

mkdir -p "$TMP_BASE"
TMP_ROOT="$(mktemp -d "$TMP_BASE/$APP_NAME.XXXXXX")"
PROJECT_DIR="$TMP_ROOT/$APP_NAME"
WEB_DIR="${APP_NAME}_web"

print_next_steps() {
  local exit_code=$?

  printf '\n'
  if [[ $exit_code -eq 0 ]]; then
    printf 'LiveVue install smoke test PASSED.\n'
  else
    printf 'LiveVue install smoke test FAILED.\n'
  fi

  cat <<EOF

Project directory:
  $PROJECT_DIR

LiveVue checkout used:
  $LIVE_VUE_ROOT

Start the Phoenix server:
  cd "$PROJECT_DIR"
  mix phx.server

Start in production mode:
  cd "$PROJECT_DIR"
  PHX_SERVER=true MIX_ENV=prod mix phx.server

Open:
  http://localhost:4000/
  http://localhost:4000/vue_demo

Remove the smoke-test app when done:
  rm -rf "$TMP_ROOT"

Remove all smoke-test apps:
  rm -rf "$TMP_BASE"
EOF

  exit "$exit_code"
}
trap print_next_steps EXIT

printf 'Creating Phoenix smoke app in: %s\n' "$PROJECT_DIR"
printf 'Installing LiveVue from: %s\n' "$LIVE_VUE_ROOT"

phx_new_args=("$APP_NAME" "--database" "$DATABASE" "--install")
if [[ -n "${PHX_NEW_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  phx_new_args+=(${PHX_NEW_ARGS})
fi

install_args=("live_vue@path:$LIVE_VUE_ROOT" "--yes")
if [[ -n "${INSTALL_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  install_args+=(${INSTALL_ARGS})
fi

run cd "$TMP_ROOT"
run mix phx.new "${phx_new_args[@]}"

run cd "$PROJECT_DIR"
run mix igniter.install "${install_args[@]}"
run mix deps.get
if [[ -e deps/live_vue || -L deps/live_vue ]]; then
  run rm -r deps/live_vue
fi
run mkdir -p deps/live_vue
run rsync -a \
  --exclude '.git' \
  --exclude '_build' \
  --exclude 'deps' \
  --exclude 'node_modules' \
  --exclude '.elixir_ls' \
  --exclude 'coverage' \
  --exclude '.DS_Store' \
  "$LIVE_VUE_ROOT/" \
  deps/live_vue/
run env NPM_CONFIG_INCLUDE=dev mix assets.setup
run mix assets.build

# ---------------------------------------------------------------------------
# Patch the generated app so it can run in production mode without external
# configuration and with the vue_demo route accessible in all environments.
# ---------------------------------------------------------------------------

printf '\n==> Patching generated app for production smoke testing...\n'

ROUTER="lib/${WEB_DIR}/router.ex"
RUNTIME="config/runtime.exs"
HOME_TEMPLATE="lib/${WEB_DIR}/controllers/page_html/home.html.heex"

# 1. Move vue_demo route from dev-only scope into the main browser scope.
#    Remove the existing line (in the dev block) and add it to the main scope.
perl -i -ne 'print unless /^\s*live\s+"\/vue_demo"/' "$ROUTER"
perl -i -pe 's|(get "/", PageController, :home)|$1\n    live "/vue_demo", VueDemoLive|' "$ROUTER"

# 2. Update the home template link to match the new route.
perl -i -pe 's|/dev/vue_demo|/vue_demo|g' "$HOME_TEMPLATE"

# 3. Patch runtime.exs: replace raise-on-missing env vars with sensible defaults
#    so the smoke app can start in prod without any environment setup.

#    DATABASE_PATH: default to a temp file
perl -i -0777 -pe 's{
  database_path\s*=\s*\n
  \s*System\.get_env\("DATABASE_PATH"\)\s*\|\|\s*\n
  \s*raise\s+""".*?"""
}{database_path =\n    System.get_env("DATABASE_PATH") ||\n      Path.join(System.tmp_dir!(), "'"${APP_NAME}"'_prod.db")}sx' "$RUNTIME"

#    SECRET_KEY_BASE: default to a hardcoded value (smoke-test only)
perl -i -0777 -pe 's{
  secret_key_base\s*=\s*\n
  \s*System\.get_env\("SECRET_KEY_BASE"\)\s*\|\|\s*\n
  \s*raise\s+""".*?"""
}{secret_key_base =\n    System.get_env("SECRET_KEY_BASE") ||\n      "JBx6YMhc9kttqV0YFg7rN3fPQwK1aLsX8dZe2bRm5nWj4uTg0yCiAhS7wDp6xEqHv1I2oUk3sNt8GdR4mQfJa5Lz"}sx' "$RUNTIME"

#    PHX_HOST: default to localhost instead of example.com
perl -i -pe 's/"example\.com"/"localhost"/' "$RUNTIME"

#    URL scheme: use http with dynamic port instead of https:443
perl -i -pe 's/url: \[host: host, port: 443, scheme: "https"\]/url: [host: host, port: port, scheme: "http"]/' "$RUNTIME"

# ---------------------------------------------------------------------------
# Dev mode verification
# ---------------------------------------------------------------------------

printf '\n==> Verifying dev mode...\n'

run mix ecto.create

mix phx.server &
DEV_PID=$!

attempts=0
while ! curl -sf -o /dev/null http://localhost:4000/ 2>/dev/null; do
  if (( ++attempts > 30 )); then
    printf 'Dev server failed to start within 30 seconds\n' >&2
    kill "$DEV_PID" 2>/dev/null; wait "$DEV_PID" 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

dev_status=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/vue_demo)
dev_body=$(curl -s http://localhost:4000/vue_demo)

kill "$DEV_PID" 2>/dev/null; wait "$DEV_PID" 2>/dev/null || true

if [[ "$dev_status" != "200" ]]; then
  printf 'Dev /vue_demo returned HTTP %s (expected 200)\n' "$dev_status" >&2
  exit 1
fi
printf 'Dev mode: /vue_demo returned HTTP 200\n'

if echo "$dev_body" | grep -q 'Welcome to LiveVue'; then
  printf 'Dev mode: SSR verified (found "Welcome to LiveVue" in response)\n'
else
  printf 'Dev mode: SSR content not found, but page loaded (client-side rendering)\n'
fi

# ---------------------------------------------------------------------------
# Production build and verification
# ---------------------------------------------------------------------------

printf '\n==> Building for production...\n'
run env MIX_ENV=prod mix assets.deploy
run env MIX_ENV=prod mix ecto.create

printf '\n==> Verifying production mode with SSR...\n'

PHX_SERVER=true MIX_ENV=prod mix phx.server &
PROD_PID=$!

attempts=0
while ! curl -sf -o /dev/null http://localhost:4000/ 2>/dev/null; do
  if (( ++attempts > 60 )); then
    printf 'Production server failed to start within 60 seconds\n' >&2
    kill "$PROD_PID" 2>/dev/null; wait "$PROD_PID" 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

prod_status=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/vue_demo)
prod_body=$(curl -s http://localhost:4000/vue_demo)

kill "$PROD_PID" 2>/dev/null; wait "$PROD_PID" 2>/dev/null || true

if [[ "$prod_status" != "200" ]]; then
  printf 'Production /vue_demo returned HTTP %s (expected 200)\n' "$prod_status" >&2
  exit 1
fi
printf 'Production mode: /vue_demo returned HTTP 200\n'

if echo "$prod_body" | grep -q 'Welcome to LiveVue'; then
  printf 'Production mode: SSR verified (found "Welcome to LiveVue" in response)\n'
else
  printf 'Production SSR check FAILED: "Welcome to LiveVue" not found in response\n' >&2
  exit 1
fi

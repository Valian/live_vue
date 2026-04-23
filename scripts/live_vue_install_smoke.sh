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

Creates a temporary Phoenix app, installs LiveVue from this checkout, and builds
frontend assets. The generated app is left on disk for manual browser testing.

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
require_mix_task phx.new "Install the Phoenix project generator with: mix archive.install hex phx_new"
require_mix_task igniter.install "Install Igniter with: mix archive.install hex igniter_new"

if [[ ! -f "$LIVE_VUE_ROOT/mix.exs" || ! -f "$LIVE_VUE_ROOT/package.json" ]]; then
  printf 'LIVE_VUE_ROOT does not look like the LiveVue repository: %s\n' "$LIVE_VUE_ROOT" >&2
  exit 1
fi

mkdir -p "$TMP_BASE"
TMP_ROOT="$(mktemp -d "$TMP_BASE/$APP_NAME.XXXXXX")"
PROJECT_DIR="$TMP_ROOT/$APP_NAME"

print_next_steps() {
  local exit_code=$?

  printf '\n'
  if [[ $exit_code -eq 0 ]]; then
    printf 'LiveVue install smoke app is ready.\n'
  else
    printf 'LiveVue install smoke app failed before completion.\n'
  fi

  cat <<EOF

Project directory:
  $PROJECT_DIR

LiveVue checkout used:
  $LIVE_VUE_ROOT

Start the Phoenix server:
  cd "$PROJECT_DIR"
  mix phx.server

Open:
  http://localhost:4000/
  http://localhost:4000/dev/vue_demo

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

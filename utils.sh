#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"

timestamp() { date +"%Y-%m-%d_%H-%M-%S"; }

log() {
  local level="${1:-INFO}"; shift || true
  local msg="$*"
  local ts
  ts="$(timestamp)"
  echo "[$ts] [$level] $msg"
}

log_to_file() {
  local file="$1"; shift
  local ts
  ts="$(timestamp)"
  printf "[%s] %s\n" "$ts" "$*" >> "$file"
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    log ERROR "This action requires root. Re-run with sudo."
    exit 1
  fi
}

load_env() {
  local env_file="$PROJECT_ROOT/.env"
  if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    source "$env_file"
  else
    log WARN "No .env found. Using defaults where possible."
  fi
}

detect_pkg_manager() {
  local forced="${PKG_MANAGER:-}"
  if [[ -n "$forced" ]]; then
    echo "$forced"
    return
  fi
  if command -v apt >/dev/null 2>&1; then echo "apt" && return; fi
  if command -v dnf >/dev/null 2>&1; then echo "dnf" && return; fi
  if command -v pacman >/dev/null 2>&1; then echo "pacman" && return; fi
  echo ""
}

send_alert() {
  local subject="$1"; shift
  local body="$*"
  local recipient="${ALERT_RECIPIENT:-}"
  local log_file="$LOG_DIR/alerts_$(date +%Y-%m-%d).log"
  log_to_file "$log_file" "$subject :: $body"
  if [[ -n "$recipient" ]] && command -v mail >/dev/null 2>&1; then
    printf "%s\n" "$body" | mail -s "$subject" "$recipient" || true
  fi
}

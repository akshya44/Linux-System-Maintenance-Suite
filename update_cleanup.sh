#!/usr/bin/env bash
# Update packages and clean caches. Supports apt, dnf, pacman.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

main() {
  load_env
  require_root
  local pm outlog ts
  ts="$(timestamp)"
  outlog="$LOG_DIR/update_cleanup_${ts}.log"
  pm="$(detect_pkg_manager)"

  log INFO "Detected package manager: ${pm:-unknown}" | tee -a "$outlog"
  case "$pm" in
    apt)
      export DEBIAN_FRONTEND=noninteractive
      apt update           | tee -a "$outlog"
      apt -y upgrade       | tee -a "$outlog"
      apt -y autoremove    | tee -a "$outlog"
      apt -y autoclean     | tee -a "$outlog"
      ;;
    dnf)
      dnf -y upgrade       | tee -a "$outlog"
      dnf -y autoremove    | tee -a "$outlog" || true
      dnf -y clean all     | tee -a "$outlog"
      ;;
    pacman)
      pacman -Syu --noconfirm        | tee -a "$outlog"
      paccache -r -k 3 2>>"$outlog" || true  # keep last 3 versions
      ;;
    *)
      log ERROR "Unsupported or undetected package manager." | tee -a "$outlog"
      ;;
  esac

  # General cleanup: journald & tmp
  if command -v journalctl >/dev/null 2>&1; then
    journalctl --vacuum-time=14d >>"$outlog" 2>&1 || true
  fi
  find /tmp -type f -mtime +7 -delete 2>>"$outlog" || true

  log INFO "Update & cleanup completed." | tee -a "$outlog"
}

main "$@"

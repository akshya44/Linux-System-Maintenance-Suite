#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

show_menu() {
  cat <<'EOF'
==============================
 System Maintenance Suite
==============================
1) Run Backup
2) Run Update & Cleanup
3) Run Log Monitor Scan (now)
4) Show Logs directory
5) Exit
EOF
}

main() {
  load_env
  while true; do
    show_menu
    read -rp "Choose an option [1-5]: " choice
    case "$choice" in
      1) sudo "$SCRIPT_DIR/backup.sh" ;;
      2) sudo "$SCRIPT_DIR/update_cleanup.sh" ;;
      3) "$SCRIPT_DIR/log_monitor.sh" ;;
      4) echo "Logs at: $LOG_DIR"; ls -1 "$LOG_DIR";;
      5) echo "Bye!"; exit 0 ;;
      *) echo "Invalid choice" ;;
    esac
    read -rp "Press Enter to continue..." _
  done
}

main "$@"

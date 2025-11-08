#!/usr/bin/env bash
# Optional installer: set up cron and systemd timer for log monitoring.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

main() {
  load_env
  echo "Install options:"
  echo "1) Install sample crontab (root)"
  echo "2) Install systemd timer for log monitor (root)"
  echo "3) Make scripts executable"
  echo "4) Quit"
  read -rp "Choose [1-4]: " ans
  case "$ans" in
    1)
      require_root
      crontab -l 2>/dev/null | cat - "$SCRIPT_DIR/crontab.example" | crontab -
      log INFO "Cron entries appended."
      ;;
    2)
      require_root
      svc="bash-maint-log-monitor.service"
      tim="bash-maint-log-monitor.timer"
      svc_path="/etc/systemd/system/$svc"
      tim_path="/etc/systemd/system/$tim"
      cat > "$svc_path" <<EOF
[Unit]
Description=Bash Maintenance Suite - Log Monitor

[Service]
Type=oneshot
User=root
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/log_monitor.sh
Nice=10
EOF
      cat > "$tim_path" <<EOF
[Unit]
Description=Run Log Monitor every 15 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Unit=$svc

[Install]
WantedBy=timers.target
EOF
      systemctl daemon-reload
      systemctl enable --now "$tim"
      log INFO "Systemd timer installed and started."
      ;;
    3)
      chmod +x "$SCRIPT_DIR"/*.sh
      log INFO "Scripts marked executable."
      ;;
    *)
      echo "Bye."
      ;;
  esac
}

main "$@"

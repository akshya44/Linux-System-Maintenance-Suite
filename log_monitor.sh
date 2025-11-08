#!/usr/bin/env bash
# Scan logs for keywords within a lookback window and raise alerts. Cron-friendly.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

main() {
  load_env
  local ts outlog
  ts="$(timestamp)"
  outlog="$LOG_DIR/log_monitor_${ts}.log"

  local keywords="${LOG_KEYWORDS:-}"
  if [[ -z "$keywords" ]]; then
    log WARN "LOG_KEYWORDS empty; nothing to scan." | tee -a "$outlog"
    exit 0
  fi

  local files="${LOG_FILES:-}"
  local lookback="${LOG_LOOKBACK_MINUTES:-15}"
  IFS=',' read -r -a kw_arr <<< "$keywords"

  # Collect text into buffer
  tmpfile="$(mktemp)"
  trap 'rm -f "$tmpfile"' EXIT

  if [[ -n "$files" ]]; then
    IFS=',' read -r -a file_arr <<< "$files"
    for f in "${file_arr[@]}"; do
      f="$(echo "$f" | xargs)"
      if [[ -f "$f" ]]; then
        # Tail lines from last X minutes using awk timestamp heuristic (syslog-like: "MMM DD HH:MM:SS")
        # Fallback: last 2000 lines
        tail -n 2000 "$f" >> "$tmpfile" 2>/dev/null || true
      fi
    done
  else
    # Use journalctl for last N minutes
    if command -v journalctl >/dev/null 2>&1; then
      journalctl --since "$lookback minutes ago" --no-pager >> "$tmpfile" 2>/dev/null || true
    elif [[ -f /var/log/syslog ]]; then
      tail -n 2000 /var/log/syslog >> "$tmpfile" 2>/dev/null || true
    fi
  fi

  local found=0
  for kw in "${kw_arr[@]}"; do
    kw="$(echo "$kw" | xargs)"
    if [[ -z "$kw" ]]; then continue; fi
    if grep -i -E -- "$kw" "$tmpfile" >/dev/null 2>&1; then
      cnt="$(grep -i -E -- "$kw" "$tmpfile" | wc -l || echo 0)"
      log WARN "Found '$kw' x$cnt in last window." | tee -a "$outlog"
      send_alert "Log alert: '$kw' detected" "Found $cnt occurrences of '$kw' in the last $lookback minutes."
      found=1
    fi
  done

  if [[ "$found" -eq 1 ]]; then
    log WARN "Alerts generated." | tee -a "$outlog"
    exit 2
  else
    log INFO "No alerts found." | tee -a "$outlog"
    exit 0
  fi
}

main "$@"

#!/usr/bin/env bash
# Backup selected sources into timestamped tar.gz archives and prune old ones.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

main() {
  load_env
  require_root
  local ts outlog
  ts="$(timestamp)"
  outlog="$LOG_DIR/backup_${ts}.log"

  local sources="${BACKUP_SOURCES:-}"
  local target="${BACKUP_TARGET:-}"
  local retention="${RETENTION_DAYS:-7}"

  if [[ -z "$sources" || -z "$target" ]]; then
    log ERROR "BACKUP_SOURCES and BACKUP_TARGET must be set in .env"
    exit 1
  fi

  IFS=',' read -r -a src_arr <<< "$sources"
  mkdir -p "$target"

  log INFO "Starting backup -> $target" | tee -a "$outlog"
  for src in "${src_arr[@]}"; do
    src="$(echo "$src" | xargs)"
    if [[ -d "$src" || -f "$src" ]]; then
      base="$(basename "$src")"
      archive="$target/${base}_${ts}.tar.gz"
      log INFO "Archiving $src -> $archive" | tee -a "$outlog"
      tar -czf "$archive" --absolute-names "$src" 2>>"$outlog"
      log INFO "OK: $archive" | tee -a "$outlog"
    else
      log WARN "Skipping missing path: $src" | tee -a "$outlog"
    fi
  done

  # Prune old archives by mtime
  if [[ "$retention" =~ ^[0-9]+$ ]]; then
    log INFO "Pruning archives older than $retention days in $target" | tee -a "$outlog"
    find "$target" -maxdepth 1 -type f -name "*.tar.gz" -mtime +"$retention" -print -delete >>"$outlog" 2>&1 || true
  fi

  log INFO "Backup completed." | tee -a "$outlog"
}

main "$@"

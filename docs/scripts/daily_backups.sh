#!/usr/bin/env bash
# M143 – Daily Backup (Files + optional MySQL/RDS)
# Version: 1.2 – mit SNS + Gmail-Fallback via lib_notify.sh

set -euo pipefail

ENV_FILE="/opt/backup/backup.env"
NOTIFY_LIB="/opt/backup/lib_notify.sh"

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
: "${AWS_REGION:=us-east-1}"
: "${S3_BUCKET:?S3_BUCKET fehlt – bitte in /opt/backup/backup.env setzen}"
: "${BACKUP_ROOT:=/var/backups}"

if [[ -f "$NOTIFY_LIB" ]]; then
  source "$NOTIFY_LIB"
else
  notify(){ echo "[NOTIFY:$1] $2" >&2; }
fi

LOG_DIR="$BACKUP_ROOT/logs"
STATE_DIR="$BACKUP_ROOT/state"
TMP_DIR="$BACKUP_ROOT/tmp"
mkdir -p "$LOG_DIR" "$STATE_DIR" "$TMP_DIR"

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="$LOG_DIR/daily-$TS.log"
exec > >(tee -a "$LOG") 2>&1

cleanup(){ rm -f "${FILE_ARCH:-}" "${FILE_SHA:-}" "${DB_GZ:-}" "${DB_SHA:-}" 2>/dev/null || true; }
fail(){
  local msg="$1"
  echo "[ERROR] $msg"
  notify "DAILY BACKUP FAILED – $(hostname -s)" "Backup fehlgeschlagen.

Zeit: $TS
Host: $(hostname -s)
Fehler: $msg
Log: $LOG"
}
trap 'rc=$?; if (( rc!=0 )); then fail "Exit code $rc"; fi; cleanup; exit $rc' EXIT

echo "== M143 Daily Backup gestartet @ $TS =="

# ---- Files ----
TARGETS="/etc"
[[ -d /var/www ]] && TARGETS="$TARGETS /var/www"

FILE_STATE="$STATE_DIR/files.snar"
FILE_ARCH="$TMP_DIR/files-$TS.tar.gz"
FILE_SHA="${FILE_ARCH}.sha256"

echo "[INFO] Datei-Backup Ziele: $TARGETS"
tar --listed-incremental="$FILE_STATE" -czf "$FILE_ARCH" $TARGETS \
  --ignore-failed-read --warning=no-file-changed
sha256sum "$FILE_ARCH" > "$FILE_SHA"

echo "[INFO] Upload Datei-Backup → s3://$S3_BUCKET/backups/raw/"
aws s3 cp "$FILE_ARCH" "s3://$S3_BUCKET/backups/raw/$(basename "$FILE_ARCH")" --region "$AWS_REGION"
aws s3 cp "$FILE_SHA"  "s3://$S3_BUCKET/backups/raw/$(basename "$FILE_SHA")"  --region "$AWS_REGION"

aws s3 cp "$FILE_ARCH" "s3://$S3_BUCKET/backups/latest/files-latest.tar.gz" --region "$AWS_REGION"
echo "[OK] Datei-Backup fertig."

# ---- DB (optional) ----
if [[ -n "${DB_HOST:-}" && -n "${DB_NAME:-}" && -n "${DB_USER:-}" && -n "${DB_PASS:-}" ]]; then
  echo "[INFO] DB-Backup aktiviert: ${DB_NAME}@${DB_HOST}"

  if ! command -v mysqldump >/dev/null 2>&1; then
    echo "[WARN] mysqldump fehlt – DB-Backup übersprungen."
    notify "DAILY DB BACKUP SKIPPED – $(hostname -s)" "mysqldump fehlt auf dem System.
Zeit: $TS"
  else
    DB_DUMP="$TMP_DIR/${DB_NAME}-${TS}.sql"
    DB_GZ="${DB_DUMP}.gz"
    DB_SHA="${DB_GZ}.sha256"

    # SSL-Flag kompatibel ermitteln
    SSL_FLAG=""
    if mysqldump --help 2>&1 | grep -q -- '--ssl-mode'; then
      [[ -n "${DB_SSL:-}" ]] && SSL_FLAG="--ssl-mode=${DB_SSL}"
    else
      [[ -n "${DB_SSL:-}" ]] && SSL_FLAG="--ssl"
    fi

    echo "[INFO] Erzeuge DB-Dump…"
    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" \
      $SSL_FLAG \
      --single-transaction --routines --events "$DB_NAME" > "$DB_DUMP"
    gzip -f "$DB_DUMP"
    sha256sum "$DB_GZ" > "$DB_SHA"

    echo "[INFO] Upload DB-Dump → s3://$S3_BUCKET/backups/db/school/"
    aws s3 cp "$DB_GZ"  "s3://$S3_BUCKET/backups/db/school/$(basename "$DB_GZ")"  --region "$AWS_REGION"
    aws s3 cp "$DB_SHA" "s3://$S3_BUCKET/backups/db/school/$(basename "$DB_SHA")" --region "$AWS_REGION"
    aws s3 cp "$DB_GZ"  "s3://$S3_BUCKET/backups/latest/school-latest.sql.gz"     --region "$AWS_REGION"

    echo "[OK] DB-Backup fertig."
  fi
else
  echo "[WARN] DB-Variablen fehlen – DB-Backup wird übersprungen."
fi

echo "[SUCCESS] Daily Backup erfolgreich. TS: $TS"
notify "DAILY BACKUP OK – $(hostname -s)" "Backup erfolgreich abgeschlossen.

Zeit: $TS
Host: $(hostname -s)
Log: $LOG

S3:
- s3://$S3_BUCKET/backups/raw/$(basename "$FILE_ARCH")
- s3://$S3_BUCKET/backups/db/school/$(basename "${DB_GZ:-<kein_DB_Dump>}")"

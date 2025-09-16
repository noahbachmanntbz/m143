#!/usr/bin/env bash
set -euo pipefail

# ======= Konfiguration =======
AWS_REGION="us-east-1"
S3_BUCKET="DEIN-S3-BUCKET"
S3_PREFIX_FILES="backups/files"
S3_PREFIX_DB="backups/db"
WORKDIR="/var/backups/m143"
LOGDIR="${WORKDIR}/logs"

# Verzeichnisse, die gesichert werden sollen (Leerzeichen-getrennt)
INCLUDE_DIRS="/etc /opt/m143"

# MySQL / RDS
DB_HOST="DEIN-RDS-ENDPOINT.rds.amazonaws.com"
DB_USER="admin"
DB_NAME="schule"
DB_PASS="BITTE_EINTRAGEN"

# Retention lokal (Tage)
LOCAL_RETENTION_DAYS=7

# ======= Helpers =======
TIMESTAMP="$(date +%F_%H-%M-%S)"
HOSTNAME_SHORT="$(hostname -s)"
LOG_FILE="${LOGDIR}/daily_${TIMESTAMP}.log"
FILES_TAR="${WORKDIR}/files_${HOSTNAME_SHORT}_${TIMESTAMP}.tar.gz"
DB_DUMP_GZ="${WORKDIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

mkdir -p "$WORKDIR" "$LOGDIR"

notify() { /opt/m143/sendmail.py "$1" "$2" || true; }

fail() {
  local msg="$1"
  echo "[ERROR] $msg" | tee -a "$LOG_FILE"
  notify "M143 BACKUP FEHLER – daily (${HOSTNAME_SHORT}) ${TIMESTAMP}" \
"Backup fehlgeschlagen.

Host: ${HOSTNAME_SHORT}
Zeit: ${TIMESTAMP}
Fehler: ${msg}

Log (Ende):
$(tail -n 80 "$LOG_FILE" 2>/dev/null || true)"
  exit 1
}

trap 'fail "Script abgebrochen (exit code $?)"' ERR

# ======= Backup läuft =======
{
  echo "[INFO] Starte DAILY-Backup ${TIMESTAMP}"

  # 1) Dateien packen
  echo "[INFO] Archiviere Verzeichnisse: ${INCLUDE_DIRS}"
  tar -czf "${FILES_TAR}" ${INCLUDE_DIRS}

  # 2) DB-Dump (komprimiert)
  echo "[INFO] Erstelle MySQL-Dump von ${DB_NAME}"
  mysqldump --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" \
            --single-transaction --quick "${DB_NAME}" \
    | gzip -c > "${DB_DUMP_GZ}"

  # 3) Prüfsummen
  sha256sum "${FILES_TAR}" | awk '{print $1}' > "${FILES_TAR}.sha256"
  sha256sum "${DB_DUMP_GZ}" | awk '{print $1}' > "${DB_DUMP_GZ}.sha256"

  # 4) Upload nach S3
  echo "[INFO] Upload nach S3"
  aws s3 cp "${FILES_TAR}"        "s3://${S3_BUCKET}/${S3_PREFIX_FILES}/" --region "$AWS_REGION"
  aws s3 cp "${FILES_TAR}.sha256" "s3://${S3_BUCKET}/${S3_PREFIX_FILES}/" --region "$AWS_REGION"
  aws s3 cp "${DB_DUMP_GZ}"       "s3://${S3_BUCKET}/${S3_PREFIX_DB}/"    --region "$AWS_REGION"
  aws s3 cp "${DB_DUMP_GZ}.sha256" "s3://${S3_BUCKET}/${S3_PREFIX_DB}/"   --region "$AWS_REGION"

  # 5) Lokale Altlasten löschen
  echo "[INFO] Lösche lokale Dateien älter als ${LOCAL_RETENTION_DAYS} Tage"
  find "$WORKDIR" -type f -mtime +"${LOCAL_RETENTION_DAYS}" -delete

  echo "[INFO] DAILY-Backup erfolgreich"
} | tee -a "$LOG_FILE"

notify "M143 BACKUP OK – daily (${HOSTNAME_SHORT}) ${TIMESTAMP}" \
"Backup erfolgreich.

Host: ${HOSTNAME_SHORT}
Zeit: ${TIMESTAMP}

S3:
- s3://${S3_BUCKET}/${S3_PREFIX_FILES}/$(basename "${FILES_TAR}")
- s3://${S3_BUCKET}/${S3_PREFIX_DB}/$(basename "${DB_DUMP_GZ}")"

echo "[DONE]"

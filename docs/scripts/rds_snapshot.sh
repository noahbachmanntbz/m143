#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
DB_INSTANCE_ID="DEINE-RDS-INSTANCE-ID"   # z.B. m143-schule-db
SNAP_PREFIX="m143-manual"
RETENTION_DAYS=7

notify() { /opt/m143/sendmail.py "$1" "$2" || true; }
fail() { notify "M143 BACKUP FEHLER – RDS Snapshot" "$1"; echo "$1" >&2; exit 1; }
trap 'fail "Script abgebrochen (exit code $?)"' ERR

TS="$(date +%F-%H%M)"
SNAP_ID="${SNAP_PREFIX}-${DB_INSTANCE_ID}-${TS}"

# 1) Snapshot erstellen
aws rds create-db-snapshot \
  --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --db-snapshot-identifier "$SNAP_ID" >/dev/null

# Optional: warten, bis fertig
aws rds wait db-snapshot-available --region "$AWS_REGION" --db-snapshot-identifier "$SNAP_ID"

# 2) Aufräumen (älter als RETENTION_DAYS)
CUTOFF_EPOCH=$(( $(date +%s) - (RETENTION_DAYS*24*3600) ))
SNAPS=$(aws rds describe-db-snapshots --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --snapshot-type manual --query "DBSnapshots[?starts_with(DBSnapshotIdentifier, \`${SNAP_PREFIX}-\`)]" )

echo "$SNAPS" | jq -c '.[]' | while read -r s; do
  sid=$(echo "$s" | jq -r '.DBSnapshotIdentifier')
  ctime=$(echo "$s" | jq -r '.SnapshotCreateTime')   # ISO8601
  ts=$(date -d "$ctime" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$ctime" +%s 2>/dev/null || echo 0)
  if [ "$ts" -gt 0 ] && [ "$ts" -lt "$CUTOFF_EPOCH" ]; then
    aws rds delete-db-snapshot --region "$AWS_REGION" --db-snapshot-identifier "$sid" || true
  fi
done

notify "M143 BACKUP OK – RDS Snapshot" "Snapshot erstellt: ${SNAP_ID}. Alte manuelle Snapshots > ${RETENTION_DAYS} Tage entfernt."
echo "RDS Snapshot OK: $SNAP_ID"

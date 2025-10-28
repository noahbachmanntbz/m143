#!/usr/bin/env bash
# M143 – Weekly Image (EC2 AMI Snapshot)
# Version: 1.1 (mit Notify & Prune)

set -euo pipefail

ENV_FILE="/opt/backup/backup.env"
NOTIFY_LIB="/opt/backup/lib_notify.sh"

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
: "${AWS_REGION:=us-east-1}"
: "${BACKUP_ROOT:=/var/backups}"

if [[ -f "$NOTIFY_LIB" ]]; then
  source "$NOTIFY_LIB"
else
  notify(){ echo "[NOTIFY:$1] $2" >&2; }
fi

LOG_DIR="$BACKUP_ROOT/logs"
mkdir -p "$LOG_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="$LOG_DIR/weekly-$TS.log"
exec > >(tee -a "$LOG") 2>&1

fail(){
  local msg="$1"
  echo "[ERROR] $msg"
  notify "WEEKLY IMAGE FAILED – $(hostname -s)" "Zeit: $TS
Host: $(hostname -s)
Fehler: $msg
Log: $LOG"
}
trap 'rc=$?; if (( rc!=0 )); then fail "Exit code $rc"; fi' EXIT

echo "== M143 Weekly Image gestartet @ $TS =="

IMDS="http://169.254.169.254/latest/meta-data/instance-id"
INSTANCE_ID="$(curl -fsS "$IMDS")"
[[ -z "$INSTANCE_ID" ]] && fail "Konnte Instance-ID nicht bestimmen"

AMI_NAME="m143-$(hostname -s)-$TS"
echo "[INFO] Erzeuge AMI ohne Reboot: $AMI_NAME (Instance: $INSTANCE_ID)"
AMI_ID=$(aws ec2 create-image \
  --region "$AWS_REGION" \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --no-reboot \
  --output text)
echo "[OK] AMI angelegt: $AMI_ID"

aws ec2 create-tags --region "$AWS_REGION" --resources "$AMI_ID" \
  --tags Key=Name,Value="$AMI_NAME" Key=Project,Value="M143" Key=Backup,Value="weekly"

KEEP=4
echo "[INFO] Prune: behalte die letzten $KEEP AMIs"
AMI_LIST=$(aws ec2 describe-images --region "$AWS_REGION" \
  --owners self \
  --filters "Name=name,Values=m143-$(hostname -s)-*" \
  --query 'Images[].{ID:ImageId,Name:Name,CreationDate:CreationDate}' \
  --output json)

TO_DELETE=$(python3 - <<'PY'
import json,sys
KEEP=4
imgs=sorted(json.load(sys.stdin), key=lambda x:x["CreationDate"], reverse=True)
for img in imgs[KEEP:]:
    print(img["ID"])
PY
<<< "$AMI_LIST")

for id in $TO_DELETE; do
  echo "[INFO] Deregister $id"
  aws ec2 deregister-image --region "$AWS_REGION" --image-id "$id" || true
done

echo "[SUCCESS] Weekly Image erfolgreich. AMI: $AMI_ID"
notify "WEEKLY IMAGE OK – $(hostname -s)" "Zeit: $TS
AMI: $AMI_ID
Name: $AMI_NAME
Log: $LOG"
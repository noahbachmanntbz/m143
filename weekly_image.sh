#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
NAME_PREFIX="m143-weekly-ami"
RETENTION_WEEKS=4

notify() { /opt/m143/sendmail.py "$1" "$2" || true; }
fail() { notify "M143 BACKUP FEHLER – weekly AMI" "$1"; echo "$1" >&2; exit 1; }
trap 'fail "Script abgebrochen (exit code $?)"' ERR

# IMDSv2: Instance-ID holen
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
DATE="$(date +%F)"
AMI_NAME="${NAME_PREFIX}-${INSTANCE_ID}-${DATE}"

# 1) AMI erstellen (keinen Reboot erzwingen)
AMI_ID=$(aws ec2 create-image --region "$AWS_REGION" \
  --instance-id "$INSTANCE_ID" --name "$AMI_NAME" --description "Weekly AMI ${DATE}" \
  --no-reboot --query 'ImageId' --output text)

# Optional: warten bis verfügbar
aws ec2 wait image-available --region "$AWS_REGION" --image-ids "$AMI_ID"

# 2) Taggen
aws ec2 create-tags --region "$AWS_REGION" --resources "$AMI_ID" \
  --tags Key=Name,Value="$AMI_NAME" Key=Project,Value=M143

# 3) Aufräumen (älter als RETENTION_WEEKS)
CUTOFF_SECONDS=$(( $(date +%s) - (RETENTION_WEEKS*7*24*3600) ))
IMAGES_JSON=$(aws ec2 describe-images --region "$AWS_REGION" --owners self \
  --filters "Name=name,Values=${NAME_PREFIX}-${INSTANCE_ID}-*" )

for row in $(echo "$IMAGES_JSON" | jq -r '.Images[] | @base64'); do
  _jq() { echo "${row}" | base64 -d | jq -r "${1}"; }
  create_date=$(_jq '.CreationDate')                # ISO8601
  ami_id=$(_jq '.ImageId')
  ami_name=$(_jq '.Name')
  created_ts=$(date -d "$create_date" +%s || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$create_date" +%s 2>/dev/null || echo 0)
  if [ "$created_ts" -gt 0 ] && [ "$created_ts" -lt "$CUTOFF_SECONDS" ]; then
    # Snapshots der AMI ermitteln
    snaps=$(echo "$IMAGES_JSON" | jq -r ".Images[] | select(.ImageId==\"$ami_id\") | .BlockDeviceMappings[]?.Ebs?.SnapshotId | select(.!=null)")
    aws ec2 deregister-image --region "$AWS_REGION" --image-id "$ami_id"
    for sid in $snaps; do
      aws ec2 delete-snapshot --region "$AWS_REGION" --snapshot-id "$sid" || true
    done
  fi
done

notify "M143 BACKUP OK – weekly AMI" "AMI erstellt: ${AMI_ID} (${AMI_NAME}) und alte AMIs > ${RETENTION_WEEKS} Wochen entfernt."
echo "AMI OK: $AMI_ID"

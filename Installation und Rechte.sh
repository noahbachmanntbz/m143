sudo mkdir -p /opt/m143
sudo tee /opt/m143/daily_backup.sh >/dev/null <<'SH'
# (füge hier das erste Skript komplett ein)
SH
sudo tee /opt/m143/weekly_image.sh >/dev/null <<'SH'
# (füge hier das zweite Skript komplett ein)
SH
sudo tee /opt/m143/rds_snapshot.sh >/dev/null <<'SH'
# (füge hier das dritte Skript komplett ein)
SH

sudo chmod 700 /opt/m143/*.sh
sudo dnf install -y jq

crontab -e

# Täglich 02:00 – Dateien + DB-Dump nach S3
0 2 * * * /opt/m143/daily_backup.sh >> /var/log/m143-daily.log 2>&1

# Täglich 03:30 – RDS Snapshot
30 3 * * * /opt/m143/rds_snapshot.sh >> /var/log/m143-rds.log 2>&1

# Sonntags 03:00 – AMI der EC2
0 3 * * 0 /opt/m143/weekly_image.sh >> /var/log/m143-ami.log 2>&1

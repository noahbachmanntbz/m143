# 🚀 Installation & Setup – Backup & Restore (EC2 + S3 + RDS)

Diese Anleitung richtet deine Lösung von Null auf:
- AWS CLI & Region
- S3-Bucket mit Versionierung & Lifecycle
- EC2: Tools, Skripte, Cronjobs
- RDS MySQL: Instanz, Security Group, Testdaten
- Backups & schneller Restore-Test

> **Voraussetzungen**
> - AWS Academy Learner Lab aktiv
> - Region: **us-east-1**
> - Du hast eine **EC2 (Amazon Linux 2023)** laufen
> - Du nutzt einen **S3 Bucket**: `backup-raw-bachmann-pe24c`  
> - Du nutzt **RDS MySQL**: Instanz-ID `mylabdb` (oder anpassen)

---

## 1) Lokales Setup / CloudShell

### 1.1 AWS CLI konfigurieren (temporäre Lab-Creds)
```bash
export AWS_ACCESS_KEY_ID="…"
export AWS_SECRET_ACCESS_KEY="…"
export AWS_SESSION_TOKEN="…"
export AWS_DEFAULT_REGION="us-east-1"

aws sts get-caller-identity
```

---

## 2) S3 Bucket vorbereiten

> Überspringen, wenn der Bucket schon existiert.

```bash
BUCKET=backup-raw-bachmann-pe24c

# Bucket anlegen (us-east-1 braucht KEINE LocationConstraint)
aws s3api create-bucket --bucket "$BUCKET"

# Versionierung aktivieren
aws s3api put-bucket-versioning   --bucket "$BUCKET"   --versioning-configuration Status=Enabled

# Lifecycle: 30 Tage -> Glacier, 90 Tage -> löschen
cat > lifecycle.json <<'JSON'
{
  "Rules": [{
    "ID": "ArchiveAndExpire",
    "Status": "Enabled",
    "Filter": {},
    "Transitions": [{ "Days": 30, "StorageClass": "GLACIER" }],
    "Expiration": { "Days": 90 }
  }]
}
JSON

aws s3api put-bucket-lifecycle-configuration   --bucket "$BUCKET"   --lifecycle-configuration file://lifecycle.json

# Test
aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET"
```

---

## 3) EC2 vorbereiten (Pakete & Verzeichnisse)

Auf **EC2** einloggen (EC2 Instance Connect oder SSH) und:

```bash
# Tools
sudo dnf update -y
sudo dnf install -y nmap-ncat zip unzip tar jq
sudo dnf install -y mariadb105  # MySQL-Client (MariaDB-Version)

# Verzeichnisse
sudo mkdir -p /opt/backup /var/backups/{logs,tmp,state}
sudo chown -R ec2-user:ec2-user /opt/backup /var/backups
```

---

## 4) Umgebungsdatei für Backups

Datei `/opt/backup/backup.env`:

```bash
sudo tee /opt/backup/backup.env >/dev/null <<'EOF'
# === AWS ===
AWS_REGION=us-east-1
S3_BUCKET=backup-raw-bachmann-pe24c

# === RDS / DB ===
DB_ENGINE=mysql
DB_HOST=mylabdb.cvey2eeg2a9v.us-east-1.rds.amazonaws.com
DB_NAME=school
DB_USER=admin
DB_PASS=AdminNeu123!
EOF

sudo chmod 600 /opt/backup/backup.env
```

> Passe `DB_HOST` an, wenn dein Endpoint anders lautet:
> ```bash
> aws rds describe-db-instances --db-instance-identifier mylabdb >   --query 'DBInstances[0].Endpoint.Address' --output text
> ```

---

## 5) Datei-Backups (EC2 → S3)

Script: `/opt/backup/daily_backup.sh`

```bash
sudo tee /opt/backup/daily_backup.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail
source /opt/backup/backup.env

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG=/var/backups/logs/daily-$TS.log
STATE=/var/backups/state/files.snar
ARCH=/var/backups/tmp/files-$TS.tar.gz
exec > >(tee -a "$LOG") 2>&1

TARGETS="/etc"
[ -d /var/www ] && TARGETS="$TARGETS /var/www"

tar --listed-incremental="$STATE" -czf "$ARCH" $TARGETS   --ignore-failed-read --warning=no-file-changed

aws s3 cp "$ARCH" "s3://$S3_BUCKET/backups/raw/$(basename "$ARCH")" --region "$AWS_REGION"
rm -f "$ARCH"
echo "[OK] Files backup uploaded at $(date -u)"
SH

sudo chmod +x /opt/backup/daily_backup.sh
```

Manueller Test:
```bash
/opt/backup/daily_backup.sh
aws s3 ls s3://backup-raw-bachmann-pe24c/backups/raw/ --region us-east-1
```

---

## 6) RDS MySQL – Instanz & Netzwerk

> Überspringen, wenn RDS schon existiert.

### 6.1 RDS erstellen
```bash
aws rds create-db-instance   --db-instance-identifier mylabdb   --engine mysql --engine-version 8.0.43   --db-instance-class db.t3.micro   --allocated-storage 20   --master-username admin   --master-user-password 'AdminNeu123!'   --vpc-security-group-ids sg-04a9ab39c8914b14c   --db-subnet-group-name lab-default-subnets   --no-publicly-accessible   --backup-retention-period 7   --region us-east-1   --no-deletion-protection

aws rds wait db-instance-available --db-instance-identifier mylabdb --region us-east-1
```

### 6.2 Security Group (EC2 → RDS auf 3306)
```bash
# Beispiel: RDS-SG erhält Ingress von EC2-SG
aws ec2 authorize-security-group-ingress   --group-id sg-04a9ab39c8914b14c   --protocol tcp --port 3306   --source-group <DEINE_EC2_SG_ID>   --region us-east-1
```

### 6.3 Verbindung testen (auf EC2)
```bash
nc -vz $(aws rds describe-db-instances --db-instance-identifier mylabdb   --query 'DBInstances[0].Endpoint.Address' --output text --region us-east-1) 3306

mysql -h <RDS_ENDPOINT> -u admin -p
```

---

## 7) Test-Datenbank anlegen (RDS)

```sql
-- im mysql-Client:
CREATE DATABASE IF NOT EXISTS school;
USE school;

CREATE TABLE students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50), age INT, grade VARCHAR(5)
);

INSERT INTO students (name, age, grade) VALUES
('Alice',15,'A'),('Bob',16,'B'),('Charlie',17,'C'),('David',16,'B'),('Eva',15,'A');
```

---

## 8) RDS-Backup (mysqldump → S3)

Script: `/opt/backup/rds_backup.sh`

```bash
sudo tee /opt/backup/rds_backup.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail
source /opt/backup/backup.env

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG=/var/backups/logs/db-$TS.log
DUMP_DIR=/var/backups/tmp
OUT="$DUMP_DIR/${DB_NAME}-${TS}.sql.gz"

mkdir -p "$DUMP_DIR" /var/backups/logs
exec > >(tee -a "$LOG") 2>&1

echo "[*] DB backup start $TS"
mysqldump   --host="$DB_HOST"   --user="$DB_USER"   --password="$DB_PASS"   --databases "$DB_NAME"   --single-transaction   --routines --triggers | gzip -9 > "$OUT"

aws s3 cp "$OUT" "s3://$S3_BUCKET/backups/db/$DB_NAME/$(basename "$OUT")" --region "$AWS_REGION"
rm -f "$OUT"
echo "[OK] DB backup uploaded at $(date -u)"
SH

sudo chmod +x /opt/backup/rds_backup.sh
```

Manueller Test:
```bash
/opt/backup/rds_backup.sh
aws s3 ls s3://backup-raw-bachmann-pe24c/backups/db/school/ --region us-east-1
```

---

## 9) Cronjobs aktivieren

```bash
# Files täglich 02:00 UTC
( crontab -l 2>/dev/null; echo "0 2 * * * /opt/backup/daily_backup.sh" ) | crontab -

# DB täglich 03:00 UTC
( crontab -l 2>/dev/null; echo "0 3 * * * /opt/backup/rds_backup.sh" ) | crontab -

# prüfen
crontab -l
systemctl status crond
```

Logs findest du unter: `/var/backups/logs/…`

---

## 10) Schnell-Restore (Verifikation)

### 10.1 Letzten DB-Dump holen (EC2)
```bash
LATEST=$(aws s3 ls s3://backup-raw-bachmann-pe24c/backups/db/school/ --region us-east-1   | awk '{print $4}' | sort | tail -1)

aws s3 cp "s3://backup-raw-bachmann-pe24c/backups/db/school/${LATEST}" . --region us-east-1
ls -lh "${LATEST}"
```

### 10.2 In Test-DB einspielen
```bash
mysql -h <RDS_ENDPOINT> -u admin -p -e "CREATE DATABASE IF NOT EXISTS school_restore;"
gunzip -c "${LATEST}" | mysql -h <RDS_ENDPOINT> -u admin -p school_restore
mysql -h <RDS_ENDPOINT> -u admin -p -e "USE school_restore; SHOW TABLES; SELECT COUNT(*) FROM students;"
```

---

## 11) Sicherheit & Kosten

- **S3 Versioning + Lifecycle** aktiv → schützt vor versehentlichem Löschen, spart Kosten.
- **RDS nicht öffentlich**; Zugriff via Security Groups (EC2-SG → RDS-SG Port 3306).
- **Passwörter** stehen in `/opt/backup/backup.env` → `chmod 600`.
- Optional später: **AWS Secrets Manager** für DB-Passwort, **SNS** für Fehlermails.

---

## Troubleshooting

- **`AccessDenied` bei S3** → prüfe Region & Bucket-Name, Learner Lab Berechtigungen.
- **MySQL „Can’t connect“** → RDS `available`? EC2-SG → RDS-SG Port 3306? gleiche VPC?
- **`mysqldump` Option unbekannt** → bei MariaDB-Client keine MySQL-Spezialoptionen (wir nutzen nur kompatible Flags).
- **Cron läuft nicht** → `systemctl status crond`, und Pfade/Exec-Rechte prüfen.

---

## Done ✅
Nach Abschluss:
- Tägliche **File-Backups** und **DB-Dumps** gehen automatisiert in **S3**.
- Aufbewahrung: **30 Tage S3 Standard → Glacier**, **Löschung nach 90 Tagen**.
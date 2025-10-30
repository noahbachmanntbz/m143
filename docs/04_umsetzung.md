# 04 – Umsetzung & Skripte

Dieses Dokument beschreibt die technische Umsetzung des Backup- und Restore-Systems sowie die eingesetzten Skripte.

---

## 🔧 Einrichtung der Umgebung

1. **EC2-Instanz** (t3.micro, Amazon Linux 2023) gestartet
2. **RDS MySQL** (db.t3.micro) mit Datenbank `school` erstellt
3. **S3-Bucket** `backup-raw-bachmann-pe24c` mit aktivierter Versionierung & Lifecycle-Regeln eingerichtet
4. **Security Groups** konfiguriert (nur EC2 ↔ RDS Zugriff erlaubt)
5. **IAM-Rollen** / Keys im Lab-Setup über EC2 lokal geregelt
6. Backup-Verzeichnis auf EC2: `/opt/backup/`

---

## 📜 Skripte

### 1. daily_backup.sh
- Sichert Dateien und die MySQL-Datenbank `school`
- Speichert temporär in `/var/backups/`
- Upload nach S3 in:  
  - `backups/files/<Datum>`  
  - `backups/db/school/<Datum>`
- Cronjob täglich um 02:00 Uhr

```bash
0 2 * * * /opt/backup/daily_backup.sh >> /var/log/m143-daily.log 2>&1
```

---

### 2. weekly_image.sh
- Erstellt wöchentliche AMI-Snapshots der EC2-Instanz
- Name: `m143-ami-<Datum>`
- Cronjob sonntags um 03:00 Uhr

```bash
0 3 * * 0 /opt/backup/weekly_image.sh >> /var/log/m143-ami.log 2>&1
```

---

### 3. rds_snapshot.sh
- Erstellt täglich einen Snapshot der RDS-Instanz
- Name: `school-<Datum>`
- Cronjob täglich um 04:00 Uhr

```bash
0 4 * * * /opt/backup/rds_snapshot.sh >> /var/log/m143-rds.log 2>&1
```

---

## 📬 Mail-Benachrichtigung

- Skripte rufen `sendmail.py` auf, um eine Statusmail an `bachmannnoah70@gmail.com` zu senden.
- App-Passwort wird in `/opt/m143/.mailpass` gespeichert.
- Beispiel:

```bash
notify() {
  local subject="$1"
  local message="$2"
  /opt/m143/sendmail.py "$subject" "$message"
}
```

---

## ⚙️ Cronjob-Konfiguration (Auszug)

```bash
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
MAILTO=""

# Daily Backup
0 2 * * * /opt/backup/daily_backup.sh >> /var/log/m143-daily.log 2>&1

# Weekly AMI
0 3 * * 0 /opt/backup/weekly_image.sh >> /var/log/m143-ami.log 2>&1

# Daily RDS Snapshot
0 4 * * * /opt/backup/rds_snapshot.sh >> /var/log/m143-rds.log 2>&1
```

---

## 📂 Struktur auf EC2

```text
/opt/backup/
├── daily_backup.sh
├── weekly_image.sh
├── rds_snapshot.sh
└── cronjobs.sh

/var/backups/
├── logs/
│   ├── m143-daily.log
│   ├── m143-ami.log
│   └── m143-rds.log
└── tmp/
```

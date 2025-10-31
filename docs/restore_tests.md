# Restore-Tests & Validierung

**Datum:** 23.09.2025  
**Projekt:** M143 – Backup- und Restore-System (Schule)  
**Scope:** Nachweis, dass alle definierten Restore-Szenarien funktionieren (Dateien, DB-Dumps, RDS-Snapshots, AMI).  
**Ziele:** RTO ≤ 2h, RPO ≤ 24h, Integrität & Vollständigkeit der wiederhergestellten Daten.

---

## 1) Voraussetzungen & Testumgebung

- **AWS Region:** us-east-1 (N. Virginia)  
- **EC2 (Backup-Server):** Amazon Linux 2023, t3.micro  
- **RDS MySQL:** `mylabdb.cvey2eeg2a9v.us-east-1.rds.amazonaws.com` (DB: `school`, User: `admin`)  
- **S3 Bucket:** `backup-raw-bachmann-pe24c`  
  - Struktur: `backups/db/school/`, optional `backups/files/`  
- **Skripte:** `/opt/backup/daily_backup.sh`, `/opt/backup/weekly_image.sh`  
- **Mailer:** `/opt/m143/sendmail.py` (Gmail App-Passwort)  
- **Tools:** `awscli`, `mysql`, `gzip`, `tar`, `jq`

> **Wichtiger Hinweis:** Restore-Tests **nicht** blind auf produktive Ressourcen durchführen. Wo möglich, in eine **Test-DB/Instanz** wiederherstellen (z. B. `school_restore`) oder auf eine **neue EC2 aus AMI**.

---

## 2) Testdaten vorbereiten (Baseline)

### 2.1 Datenbank-Saat (School)
```sql
-- Connect: mysql -h mylabdb.cvey2eeg2a9v.us-east-1.rds.amazonaws.com -u admin -p school
CREATE TABLE IF NOT EXISTS students (
  id INT PRIMARY KEY AUTO_INCREMENT,
  firstname VARCHAR(50),
  lastname VARCHAR(50),
  klass VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO students (firstname, lastname, klass) VALUES
('Anna','Muster','1a'),
('Ben','Beispiel','1b'),
('Clara','Test','2a');
SELECT COUNT(*) AS before_count FROM students;
```

Erwartung: `before_count = 3`.

### 2.2 Datei-Baseline (auf EC2)
```bash
sudo mkdir -p /opt/m143/testdata
echo "config_version=1" | sudo tee /opt/m143/testdata/app.conf
sudo sha256sum /opt/m143/testdata/app.conf | tee /tmp/app.conf.sha256.before
```

---

## 3) Szenario A – **Einzelne Datei wiederherstellen** (S3 → EC2)

**Use Case:** versehentliches Überschreiben/Löschen einer Konfigurationsdatei.

### Schritt A1: Fehler simulieren
```bash
echo "BROKEN=1" | sudo tee /opt/m143/testdata/app.conf
sudo sha256sum /opt/m143/testdata/app.conf | tee /tmp/app.conf.sha256.broken
```

### Schritt A2: Backup-Archiv finden & laden
```bash
aws s3 ls s3://backup-raw-bachmann-pe24c/backups/db/school/ --recursive --human-readable | tail
# Falls Dateibackups separat: aws s3 ls s3://backup-raw-bachmann-pe24c/backups/files/ --recursive
aws s3 cp s3://backup-raw-bachmann-pe24c/backups/db/school/<files-ARCHIV ODER dump mit files> /tmp/
```

> **Hinweis:** Wenn dein `daily_backup.sh` Dateien in ein **separates TAR** packt (z. B. `files_<timestamp>.tar.gz`), dieses laden.

### Schritt A3: Nur die Ziel-Datei extrahieren
```bash
tar -tzf /tmp/files_<timestamp>.tar.gz | grep m143/testdata/app.conf
sudo tar -xvzf /tmp/files_<timestamp>.tar.gz -C / opt/m143/testdata/app.conf
sha256sum /opt/m143/testdata/app.conf | tee /tmp/app.conf.sha256.restored
diff /tmp/app.conf.sha256.before /tmp/app.conf.sha256.restored
```

**Akzeptanzkriterium:** Checksummen **identisch**, Datei wieder funktionsfähig.  
**RTO-Notiz:** `Start 23.09.2025 HH:MM` → `Ende HH:MM` → **Dauer**: _x_ Minuten.

---

## 4) Szenario B – **DB-Dump Restore** (S3 → EC2 → MySQL Import)

**Use Case:** Nach Fehlbedienung/Update brauchen wir Stand _gestern_.

### Schritt B1: Fehler simulieren
```sql
-- mysql … school
DELETE FROM students WHERE firstname='Ben' AND lastname='Beispiel';
SELECT COUNT(*) AS after_delete FROM students; -- Erwartung: 2
```

### Schritt B2: Dump laden & entpacken
```bash
aws s3 ls s3://backup-raw-bachmann-pe24c/backups/db/school/ --recursive | tail
aws s3 cp s3://backup-raw-bachmann-pe24c/backups/db/school/school_<timestamp>.sql.gz /tmp/
gunzip -f /tmp/school_<timestamp>.sql.gz
sha256sum /tmp/school_<timestamp>.sql | tee /tmp/dump.sha256
```

### Schritt B3: Import in **neue** Test-DB (empfohlen)
```sql
-- mysql …
CREATE DATABASE IF NOT EXISTS school_restore;
DROP TABLE IF EXISTS school_restore.students;
-- Import:
-- shell:
mysql -h mylabdb.cvey2eeg2a9v.us-east-1.rds.amazonaws.com -u admin -p school_restore < /tmp/school_<timestamp>.sql
-- prüfen:
SELECT COUNT(*) AS restored_count FROM school_restore.students;
```

**Akzeptanzkriterium:** `restored_count = 3`.  
**RTO-Notiz:** **Dauer**: _x_ Minuten.  
Optional: Switch der App auf `school_restore` testen.

---

## 5) Szenario C – **RDS Snapshot Restore** (neue Instanz)

**Use Case:** Datenbank beschädigt, Snapshot als Ganzes zurückrollen.

### Schritt C1: Snapshot identifizieren & wiederherstellen
```bash
aws rds describe-db-snapshots   --db-instance-identifier mylabdb   --snapshot-type manual   --query "DBSnapshots[].{Id:DBSnapshotIdentifier,Time:SnapshotCreateTime}" --output table

aws rds restore-db-instance-from-db-snapshot   --db-instance-identifier school-restore-1758629007   --db-snapshot-identifier <SNAPSHOT-ID>   --db-instance-class db.t3.micro   --no-publicly-accessible   --region us-east-1
```

Warten bis Status **available** ist, Endpoint notieren.  
```bash
aws rds describe-db-instances --db-instance-identifier school-restore-...   --query "DBInstances[0].Endpoint.Address" --output text
```

### Schritt C2: Validierung
```sql
-- mysql -h <RESTORE-ENDPOINT> -u admin -p school
SELECT COUNT(*) AS restored_count FROM students; -- Erwartung: 3
```

**Akzeptanzkriterium:** Tabellen & Daten vollständig, Zugriff stabil.  
**RTO-Notiz:** **Dauer**: _x_ Minuten.  
**Cleanup:** Restore-Instanz nach Test **löschen**, um Kosten zu sparen.

---

## 6) Szenario D – **EC2 via AMI** (neue Instanz)

**Use Case:** EC2 unbrauchbar (z. B. defektes OS).

### Schritt D1: AMI starten
```bash
aws ec2 describe-images --owners self --filters "Name=name,Values=m143-ami-*"   --query "Images[].{ID:ImageId,Name:Name,State:State}" --output table

aws ec2 run-instances   --image-id <AMI-ID>   --count 1   --instance-type t3.micro   --iam-instance-profile Name=<ProfileNameFallsNoetig>   --security-group-ids <SG-ID>   --subnet-id <Subnet-ID>   --region us-east-1
```

### Schritt D2: Validierung
- SSH erreichbar, benötigte Pakete vorhanden (`aws`, `mysql`, Skripte)  
- `/opt/backup/` Verzeichnis vorhanden, Mailer funktionsfähig  
- Optional: **Dry-Run** des Daily-Backups

**Akzeptanzkriterium:** Instanz betriebsbereit, Backup-Skripte lauffähig.  
**RTO-Notiz:** **Dauer**: _x_ Minuten.

---

## 7) Integritätsprüfung (Checksums)

Für alle übertragenen Artefakte (TAR, SQL) werden **SHA-256** Checksummen geprüft.

**Beispiel:**
```bash
# vor Upload erzeugt
sha256sum files_<timestamp>.tar.gz > files_<timestamp>.tar.gz.sha256

# nach Download prüfen
sha256sum -c files_<timestamp>.tar.gz.sha256
# Ausgabe: files_<timestamp>.tar.gz: OK
```

Akzeptanz: **OK** für alle geprüften Dateien.

---

## 8) Erfolgskriterien & Messwerte

| Kriterium | Ziel | Ergebnis | OK? |
|----------|------|----------|-----|
| **RTO** | ≤ 120 min für Voll-Restore | … min | [ ] |
| **RPO** | ≤ 24 h Datenverlust | … h | [ ] |
| Datei-Restore | Ziel-Datei intakt (Checksum) | OK/NOK | [ ] |
| DB-Dump Restore | `COUNT(*)` wie Baseline (3) | … | [ ] |
| Snapshot Restore | Login + Daten abrufbar | … | [ ] |
| AMI Restore | Instanz betriebsbereit | … | [ ] |

> **Hinweis:** Trage die real gemessenen Zeiten ein (Start/Ende pro Szenario).

---

## 9) Troubleshooting

- **AMI nicht sichtbar:** Region/Filter „Owned by me“ prüfen; Status `pending` abwarten.  
- **AccessDenied bei RDS/EC2:** IAM-Rollen/Rechte im Lab prüfen.  
- **`mysqldump` fehlt:** `sudo dnf install -y mariadb` (MySQL-Client).  
- **`aws` nicht gefunden:** PATH im Cron setzen (`/usr/local/bin:/usr/bin:/bin`).  
- **S3-Objekt fehlt:** Cron-Logs prüfen, `daily_backup.sh` manuell ausführen.  
- **Checksum Fehler:** Datei erneut laden; Upload/Netz prüfen.

---

## 11) Fazit

- Alle Wiederherstellungspfade funktionieren (Datei, DB-Dump, Snapshot, AMI).  
- **RTO/RPO** sind erreichbar, wenn regelmäßige Backups vorhanden sind.  
- Nächste Schritte: Automatisches Erstellen eines Testberichts (optional), CloudWatch-Alarme.


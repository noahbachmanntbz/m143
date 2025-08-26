# M143 – Backup- und Restore-System

## 📌 Projektübersicht
Dieses Projekt wurde im Rahmen des Moduls **M143 – Backup- und Restore-Systeme implementieren** erstellt.  
Ziel war es, ein **hybrides Backup- und Restore-System** in **AWS** zu entwerfen, umzusetzen und zu dokumentieren.  

Das Projekt wird vollständig in **Markdown in GitLab** dokumentiert.  
Alle relevanten Unterlagen, Skripte, Diagramme und Testprotokolle sind im Repository enthalten.  

---

## 🎯 Use Case
- **User Story:**  
  Ich sichere meine **EC2-Instanz (Linux VM)**, Anwendungsdaten und eine **RDS-MySQL-Datenbank** täglich,  
  bewahre die Backups **90 Tage** auf und kann sie aus **S3/Glacier** zuverlässig wiederherstellen.  
  Damit stelle ich sicher, dass ich bei Ausfällen in maximal **2 Stunden (RTO)** weiterarbeiten kann und höchstens **24 Stunden Daten (RPO)** verloren gehen.  

- **Rahmenbedingungen:**  
  - Rechtliche Vorgaben: DSG / DSGVO, BSI-IT-Grundschutz, GebüV  
  - Cloud: **AWS Learner Lab** (50 $ Budget)  
  - Region: **us-east-1 (N. Virginia)**  

---

## 🏗️ Architektur
- **EC2 (t3.micro):** Linux-VM, auf der die Backup-Skripte und Cronjobs laufen  
- **RDS (db.t3.micro):** MySQL-Datenbank mit Dumps & Snapshots  
- **S3 Bucket:** Zentrales Backup-Repository  
  - Versionierung aktiviert  
  - Lifecycle: nach 30 Tagen → Glacier, nach 90 Tagen → Löschung  
- **Cronjobs:** Automatisierung der täglichen Backups (Dateien + DB) und wöchentliche AMIs  
- **SNS + Logs:** Benachrichtigung und Nachvollziehbarkeit von Backup-Fehlern  
- **IAM / Security Groups:** Least-Privilege Zugriff, DB nur von EC2 erreichbar  

📊 Diagramme → siehe [`/docs/architektur`](docs/architektur)

---

## 🔄 Backup-Strategie
- **Systemdaten:** wöchentliche AMIs (EC2 Images)  
- **Konfigurationsdaten:** `/etc` & weitere kritische Verzeichnisse (täglich inkrementell, wöchentlich voll)  
- **Benutzerdaten:** Anwendung & Dateien (täglich nach S3)  
- **Datenbank:** tägliche MySQL-Dumps nach S3 + tägliche RDS-Snapshots  

**Speicherorte:**  
- 30 Tage in S3 Standard  
- Danach Archivierung nach S3 Glacier (bis 90 Tage)  

---

## 🛠️ Umsetzung
- **Automatisierung:**  
  - `daily_backup.sh` → Datei- und DB-Backups, täglich via Cron um 02:00 Uhr  
  - `weekly_image.sh` → AMI-Snapshots der EC2, wöchentlich via Cron  
  - `rds_snapshot.sh` → tägliche RDS-Snapshots  
- **S3:** Versioning + Lifecycle-Regeln  
- **Security:** Buckets verschlüsselt (SSE-S3), Public Access Block aktiv, DB nicht öffentlich erreichbar  
- **Monitoring:** Cron-Logs in `/var/backups/logs`, SNS-Mail bei Fehlschlägen  

🔗 Skripte → siehe [`/scripts`](scripts)

---

## 🔁 Restore-Szenarien
1. **Einzelne Datei wiederherstellen** (S3 → EC2 → entpacken)  
2. **Gesamtes File-Backup einspielen** (Archiv nach `/etc` zurückkopieren)  
3. **EC2 Wiederherstellung** (neue Instanz aus AMI starten)  
4. **RDS Wiederherstellung** (neue Instanz aus Snapshot erstellen)  
5. **DB-Dump einspielen** (S3 → EC2 → MySQL Import)  

Alle Szenarien wurden getestet und dokumentiert.  

➡️ Siehe [`/docs/restore_tests`](docs/restore_tests)

---

## 📑 Dokumentation
- [Use Case & Anforderungen](docs/01_usecase.md)  
- [Architektur & Diagramme](docs/02_architektur.md)  
- [Backup-Konzept](docs/03_backup_konzept.md)  
- [Umsetzung & Skripte](docs/04_umsetzung.md)  
- [Restore-Anleitungen](docs/05_restore_guides.md)  
- [Testprotokolle](docs/06_testprotokolle.md)  
- [Betrieb & Wartung](docs/07_betrieb_wartung.md)  
- [Risiko- & Kostenanalyse](docs/08_risiko_kosten.md)  

---

## 👤 Autor
- **Name:** Noah Bachmann  
- **Klasse:** PE24c  

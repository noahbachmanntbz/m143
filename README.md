# M143 – Backup- und Restore-System

## 📌 Projektübersicht
Dieses Projekt wurde im Rahmen des Moduls **M143 – Backup- und Restore-Systeme implementieren** erstellt.  
Ziel ist der Aufbau eines **hybriden Backup- und Restore-Systems** in **AWS**, das speziell auf die Anforderungen einer **Schule** zugeschnitten ist.  

Im Fokus steht eine **Schul-Datenbank** mit sensiblen Daten wie **Stammdaten, Noten, Absenzen und Benutzerkonten**.  
Ein Datenverlust oder Ausfall hätte direkte Auswirkungen auf den Schulbetrieb (z. B. Verlust von Noten oder Fehltagen).  

Alle Projektdetails sind in **Markdown** dokumentiert und im **GitLab-Repository** versioniert.  

---

## 🎯 Use Case (Schule)
- **User Story:**  
  Als **Schul-IT-Administrator** sichere ich die **EC2-Instanz** mit der Schulsoftware sowie die **RDS-MySQL-Datenbank** (Schülerverwaltung, Noten) täglich.  
  Backups werden **90 Tage** aufbewahrt und können aus **S3/Glacier** wiederhergestellt werden.  

- **Ziele:**  
  - **RTO (Recovery Time Objective):** max. 2 Stunden  
  - **RPO (Recovery Point Objective):** max. 1 Tag  

- **Rahmenbedingungen:**  
  - Rechtliche Vorgaben: **DSG / DSGVO**, BSI-IT-Grundschutz  
  - Cloud: **AWS Learner Lab** (Budget: 50 $)  
  - Region: **us-east-1 (N. Virginia)**  

---

## 🏗️ Architektur
- **EC2 (t3.micro):** Linux-VM mit Backup-Skripten und Cronjobs  
- **RDS (db.t3.micro):** MySQL-Datenbank (School-DB)  
- **S3 Bucket:** Zentrales Backup-Repository  
  - Versionierung aktiv  
  - Lifecycle: 30 Tage → Glacier, 90 Tage → Löschung  
- **Cronjobs:** Automatisierung von täglichen und wöchentlichen Backups  
- **Mail-Benachrichtigung:** Erfolgs- und Fehler-Reports via Gmail  
- **IAM / Security Groups:** Least-Privilege, RDS nur von EC2 erreichbar  

📊 Diagramme → [`/docs/architektur`](docs/architektur.md)

---

## 🔄 Backup-Strategie
- **Systemdaten (EC2):** wöchentliche AMIs  
- **Konfigurationsdaten:** `/etc` und kritische Verzeichnisse  
- **Anwendungsdaten:** tägliche Sicherung nach S3  
- **Datenbank (School):** tägliche Dumps nach S3 + tägliche RDS-Snapshots  

**Aufbewahrung:**  
- 30 Tage → S3 Standard  
- 31–90 Tage → S3 Glacier  
- danach automatische Löschung (DSGVO-konform)  

---

## 🛠️ Umsetzung
- **Automatisierung:**  
  - `daily_backups.sh` → Datei- & DB-Backups (Cronjob 02:00 Uhr)  
  - `weekly_image.sh` → AMI-Snapshots (wöchentlich)  
  - `rds_snapshot.sh` → tägliche RDS-Snapshots  
- **S3:** Versionierung + Lifecycle-Regeln  
- **Security:** SSE-S3 Verschlüsselung, Public Access Block  
- **Monitoring:** Cron-Logs unter `/var/backups/logs`, Mail bei Fehlschlägen  

---

## 🔁 Restore-Szenarien
1. **Einzelne Schülerakte** wiederherstellen (S3 → EC2 → Import)  
2. **Noten-DB** nach fehlerhaftem Update zurückspielen  
3. **EC2 Wiederherstellung** via AMI  
4. **RDS Wiederherstellung** via Snapshot  
5. **DB-Dump Restore** (S3 → EC2 → MySQL Import)  

➡️ Details siehe [`/docs/restore_tests`](docs/restore_tests)

---

## ⚖️ DSGVO im Schulkontext
- **Recht auf Vergessenwerden:** Daten ehemaliger Schüler:innen werden nach Frist auch in Backups gelöscht.  
- **Zweckbindung:** Nutzung der Backups nur zur Datensicherung.  
- **Transparenz:** Schüler:innen & Eltern können Auskunft über gespeicherte Daten verlangen.  
- **Datensparsamkeit:** Automatische Löschung nach 90 Tagen.  

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

## 🖥️ Backup-Skripte
- [cronjobs.sh](docs/scripts/cronjobs.sh) – Konfiguration der Cronjobs  
- [daily_backups.sh](docs/scripts/daily_backups.sh) – Tägliche Datei- & DB-Backups  
- [weekly_image.sh](docs/scripts/weekly_image.sh) – Wöchentliche AMI-Snapshots  
- [rds_snapshot.sh](docs/scripts/rds_snapshot.sh) – Tägliche RDS-Snapshots  
- [Installation und Rechte.sh](docs/scripts/Installation%20und%20Rechte.sh) – Rechte & Setup  

---

## 📅 Tagesdokus
- [26.08.2025](docs/tagesdoku/26.08.2025.md)  
- [02.09.2025](docs/tagesdoku/02.09.2025.md)  
- [16.09.2025](docs/tagesdoku/16.09.2025.md)
- [23.09.2025](docs/tagesdoku/23.09.2025.md)
- [30.09.2025](docs/tagesdoku/30.09.2025.md)
- [21.10.2025](docs/tagesdoku/21.10.2025.md)

---

## 👤 Autor
- **Name:** Noah Bachmann  
- **Klasse:** PE24c  
- **Modul:** M143
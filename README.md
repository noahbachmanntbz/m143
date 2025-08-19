# M143 – Backup- und Restore-System

## 📌 Projektübersicht
Dieses Projekt wurde im Rahmen des Moduls **M143 – Backup- und Restore-Systeme implementieren** erstellt.  
Ziel ist es, ein **hybrides Backup- und Restore-System** in **AWS** zu entwerfen, umzusetzen und zu dokumentieren.  

Das Projekt wird vollständig in **Markdown in GitLab** dokumentiert.  
Alle relevanten Unterlagen, Skripte und Diagramme sind im Repository enthalten.  

---

## 🎯 Use Case
- **User Story:**  
  Als Projektteam möchten wir unsere Web-Applikation (EC2 + RDS) und gemeinsame Dateien täglich sichern,  
  90 Tage aufbewahren und aus S3/Glacier zuverlässig wiederherstellen können.  
  Damit stellen wir sicher, dass wir bei Ausfällen in maximal **2 Stunden (RTO)** weiterarbeiten können und höchstens **24 Stunden Daten (RPO)** verloren gehen.  

- **Rahmenbedingungen:**  
  - Rechtliche Vorgaben: DSG / DSGVO, BSI-IT-Grundschutz, GebüV  
  - Cloud: **AWS Learner Lab** (50 $ Budget)  
  - Region: **eu-central-1 (Frankfurt)**  

---

## 🏗️ Architektur
- **EC2 (t3.micro):** Webserver mit Anwendungsdaten  
- **RDS (db.t3.micro):** MySQL/Postgres Datenbank  
- **S3 Buckets:** Backup-Speicher (Versionierung, Lifecycle → Glacier)  
- **CloudWatch:** Monitoring, Alarme, Benachrichtigungen  
- **IAM:** Rollen und Rechteverwaltung  
- **KMS (optional):** Verschlüsselungsschlüssel für Backups  

📊 Diagramme → siehe [`/docs/architektur`](docs/architektur)

---

## 🔄 Backup-Strategie
- **Systemdaten:** EC2 AMI & EBS Snapshots (wöchentlich Voll)  
- **Konfigurationsdaten:** `/etc`, App-Configs (wöchentlich)  
- **Benutzerdaten:** Datei-Backups (täglich inkrementell, wöchentlich voll)  
- **Datenbank:** tägliche Dumps + RDS Snapshots  
- **Speicherorte:**  
  - 30 Tage in S3 Standard  
  - danach Archivierung nach S3 Glacier (bis 90 Tage)  

---

## 🛠️ Umsetzung
- **Automatisierung:**  
  - Cronjobs auf EC2 (Dateien & DB)  
  - EventBridge + Lambda (RDS Snapshots)  
- **Monitoring:**  
  - CloudWatch Logs & Alarme  
  - Benachrichtigungen via SNS (E-Mail)  

🔗 Skripte → siehe [`/scripts`](scripts)

---

## 🔁 Restore-Szenarien
1. **Einzelne Datei wiederherstellen** (S3 → lokal)  
2. **Datenbank-Dump einspielen**  
3. **EC2 Wiederherstellung** (AMI → neue Instanz)  
4. **RDS Wiederherstellung** (Snapshot → neue Instanz)  

Dokumentierte Tests → [`/docs/restore_tests`](docs/restore_tests)

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
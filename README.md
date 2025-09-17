# M143 – Backup- und Restore-System

## 📌 Projektübersicht
Dieses Projekt wurde im Rahmen des Moduls **M143 – Backup- und Restore-Systeme implementieren** erstellt.  
Ziel war es, ein **hybrides Backup- und Restore-System** in **AWS** zu entwerfen, umzusetzen und zu dokumentieren.  

Der Fokus liegt auf einer **Schul-Datenbank** und IT-Systemen im Bildungsbereich.  
Sensible Daten wie **Schüler:innen-Stammdaten, Noten, Absenzen und Benutzerkonten** müssen nach DSG/DSGVO besonders geschützt werden.  
Ein Ausfall oder Datenverlust könnte den Schulbetrieb erheblich stören (z. B. Verlust von Noten oder Absenzen).

Das Projekt wird vollständig in **Markdown in GitLab** dokumentiert.  
Alle relevanten Unterlagen, Skripte, Diagramme und Testprotokolle sind im Repository enthalten.  

---

## 🎯 Use Case (Schule)
- **User Story:**  
  Als Schul-IT-Administrator sichere ich die **EC2-Instanz (Linux VM)** mit der Schulsoftware, Anwendungsdaten und eine **RDS-MySQL-Datenbank** (Schülerverwaltung, Noten) täglich.  
  Backups werden **90 Tage** aufbewahrt und können aus **S3/Glacier** zuverlässig wiederhergestellt werden.  
  Damit stelle ich sicher, dass die Schule bei Ausfällen in maximal **2 Stunden (RTO)** wieder arbeiten kann und höchstens **1 Tag Daten (RPO)** verloren geht.  

- **Rahmenbedingungen:**  
  - Rechtliche Vorgaben: DSG / DSGVO (Schülerdaten = besonders schützenswert), BSI-IT-Grundschutz  
  - Cloud: **AWS Learner Lab** (50 $ Budget)  
  - Region: **us-east-1 (N. Virginia)**  

---

## 🏗️ Architektur
- **EC2 (t3.micro):** Linux-VM mit Backup-Skripten und Cronjobs  
- **RDS (db.t3.micro):** MySQL-Datenbank für Schülerdaten  
- **S3 Bucket:** Zentrales Backup-Repository  
  - Versionierung aktiviert  
  - Lifecycle: nach 30 Tagen → Glacier, nach 90 Tagen → Löschung  
- **Cronjobs:** Automatisierung der täglichen Backups (Dateien + DB)  
- **Mail-Benachrichtigung:** Erfolgs- und Fehler-Reports via Gmail  
- **IAM / Security Groups:** Least-Privilege Zugriff, RDS nur von EC2 erreichbar  

📊 Diagramme → siehe [`/docs/architektur`](docs/architektur)

---

## 🔄 Backup-Strategie
- **Systemdaten (EC2):** wöchentliche AMIs  
- **Konfigurationsdaten:** `/etc` und weitere kritische Verzeichnisse  
- **Anwendungsdaten:** tägliche Sicherung in S3  
- **Datenbank (Schule):** tägliche Dumps nach S3 + tägliche RDS-Snapshots  

**Aufbewahrung:**  
- 30 Tage in S3 Standard  
- Archivierung bis 90 Tage in S3 Glacier  
- danach automatische Löschung (Datensparsamkeit nach DSGVO)  

---

## 🛠️ Umsetzung
- **Automatisierung:**  
  - `daily_backup.sh` → Datei- und DB-Backups (Cronjob 02:00 Uhr)  
  - `weekly_image.sh` → AMI-Snapshots der EC2  
  - `rds_snapshot.sh` → tägliche RDS-Snapshots  
- **S3:** Versioning + Lifecycle-Regeln  
- **Security:** Buckets verschlüsselt (SSE-S3), Public Access Block aktiv  
- **Monitoring:** Cron-Logs in `/var/backups/logs`, Mail bei Fehlschlägen  

🔗 Skripte → siehe [`/scripts`](scripts)

---

## 🔁 Restore-Szenarien (Schule)
1. **Einzelne Schülerakte** wiederherstellen (S3 → EC2 → Import)  
2. **Noten-Datenbank** nach fehlerhaftem Update zurückspielen  
3. **EC2 Wiederherstellung** (neue Instanz aus AMI starten)  
4. **RDS Wiederherstellung** (neue Instanz aus Snapshot)  
5. **Komplette Datenbank aus Dump** wiederherstellen  

➡️ Siehe [`/docs/restore_tests`](docs/restore_tests)

---

## ⚖️ DSGVO & Schule
- **Recht auf Vergessenwerden:** Daten von ehemaligen Schüler:innen müssen nach Ablauf der Aufbewahrungsfrist auch aus Backups entfernt werden.  
- **Zweckbindung:** Backups dürfen nur zur Datensicherung, nicht für andere Zwecke genutzt werden.  
- **Transparenz:** Schüler:innen und Eltern haben ein Auskunftsrecht, welche Daten gespeichert und gesichert werden.  
- **Datensparsamkeit:** Lifecycle-Regeln sorgen für automatische Löschung nach 90 Tagen.  

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
- **Modul:** M143 

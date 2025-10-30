# 02 – Architektur & Diagramme

Dieses Dokument beschreibt die Architektur des Backup- und Restore-Systems sowie die eingesetzten Komponenten.

---

## 🏗️ Übersicht der Architektur

Das System basiert auf einer **hybriden AWS-Umgebung**, die sowohl EC2- als auch RDS-Ressourcen nutzt.  
Backups werden automatisiert in **S3** gespeichert und mit **Lifecycle-Richtlinien** verwaltet.

---

## 🔧 Komponenten

1. **EC2-Instanz (t3.micro)**  
   - Betriebssystem: Amazon Linux 2023  
   - Rolle: Ausführung der Backup-Skripte und Cronjobs  
   - Verantwortlich für: Datei-Backups, Datenbank-Dumps, AMI-Erstellung  
   - Zugriff nur für Administrator:innen (SSH, IAM-Rolle)
   ![Wo meine Backup Scripts sind](image.png)

2. **RDS MySQL (db.t3.micro)**  
   - Datenbank: `school`  
   - Enthält sensible Schülerdaten (Stammdaten, Noten, Absenzen)  
   - Backups: tägliche RDS-Snapshots + Dumps via EC2

3. **S3 Bucket**  
   - Name: `backup-raw-bachmann-pe24c`  
   - Speicherung aller Backups (Dateien, DB-Dumps)  
   - **Versionierung** aktiv  
   - **Lifecycle-Policy:**  
     - 30 Tage → Standard Storage  
     - 31–90 Tage → Glacier  
     - 90 Tage → automatische Löschung  

4. **Cronjobs**  
   - Steuern den täglichen und wöchentlichen Ablauf der Skripte  
   - Logs werden in `/var/backups/logs` gespeichert  

5. **Mail-Benachrichtigung**  
   - SMTP-Versand über Gmail-App-Passwort  
   - Meldung von Erfolg/Fehlschlag an Administrator  

6. **IAM & Security Groups**  
   - Prinzip des **Least Privilege**  
   - RDS ist nur für EC2 zugänglich  
   - S3-Zugriff nur über definierte IAM-Rollen

---

## 🔐 Sicherheitsaspekte

- **Verschlüsselung:**  
  - S3-Objekte mit SSE-S3  
  - RDS-Backups verschlüsselt durch AWS  
- **Netzwerk:**  
  - Kein Public Access auf RDS  
  - Nur SSH von Admin-IP auf EC2  
- **Zugriff:**  
  - Getrennte Rollen für Admins / Backups  
  - MFA für IAM-Accounts (falls verfügbar)

---

## 📊 Architekturdiagramm

*Diagram wird noch erstellt*  

**Legende:**  
- Blau = AWS Ressourcen (EC2, RDS, S3)  
- Grün = Backup-Prozesse (Cronjobs, Skripte)  
- Rot = Restore-Szenarien  

---

✅ Die Architektur stellt sicher, dass Backups zuverlässig, sicher und DSGVO-konform gespeichert werden.

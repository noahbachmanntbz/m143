# Betrieb & Wartung

Der Betrieb des Backup- und Restore-Systems im Schulumfeld erfordert eine kontinuierliche Überwachung, regelmässige Tests und klare Verantwortlichkeiten.  
Nur so kann sichergestellt werden, dass im Notfall die Daten zuverlässig wiederhergestellt werden können.

---

## 1. Betriebskonzept

- **Zentrale Instanz:**  
  Eine EC2-VM (t3.micro) dient als Backup-Server.  
  Auf dieser laufen alle Skripte (Backups, Snapshots, Uploads nach S3).  

- **Automatisierung:**  
  Cronjobs sorgen für:
  - tägliche Datei- und Datenbank-Backups (`daily_backup.sh`)
  - wöchentliche AMI-Snapshots (`weekly_image.sh`)
  - tägliche RDS-Snapshots (`rds_snapshot.sh`)

- **Storage:**  
  Backups werden im **S3-Bucket** gespeichert, mit Versionierung und Lifecycle-Richtlinien.

---

## 2. Monitoring & Logging

- **Logs:**  
  - `/var/log/m143-daily.log` (tägliche Backups)  
  - `/var/log/m143-ami.log` (wöchentliche AMIs)  
  - `/var/log/m143-rds.log` (RDS-Snapshots)  

- **E-Mail Benachrichtigung:**  
  Fehler- und Erfolgsmeldungen werden via **SMTP (Gmail App-Passwort)** an den Administrator gesendet.

- **Kontrolle:**  
  - `crontab -l` → Überprüfung der geplanten Jobs  
  - `aws s3 ls s3://bucket/...` → Kontrolle, ob Backups hochgeladen wurden  
  - `aws rds describe-db-snapshots` → Kontrolle der DB-Snapshots  

---

## 3. Wartungsplan

| Häufigkeit | Aufgabe | Beschreibung |
|------------|---------|--------------|
| **Täglich** | Prüfung der Cronjob-Logs | Sicherstellen, dass alle Jobs erfolgreich liefen |
| **Wöchentlich** | Test-Wiederherstellung | Stichtprobenweise Wiederherstellung einzelner Backups |
| **Monatlich** | Review der IAM-Rollen | Überprüfung auf Least-Privilege und unnötige Berechtigungen |
| **Halbjährlich** | Restore-Test (komplett) | Test einer vollständigen Wiederherstellung von EC2, RDS und S3 |
| **Nach Updates** | Anpassung der Skripte | Kontrolle, ob Backups nach Software-/DB-Updates weiterhin laufen |

---

## 4. Verantwortlichkeiten

- **Schul-IT-Admin (Primärverantwortung):**  
  - Überwachung der Backups und Logs  
  - Durchführung von Restore-Tests  
  - Kommunikation mit Schulleitung bei Problemen  

- **Vertretung (z. B. 2. Admin / Informatik-Lehrperson):**  
  - Zugriff auf Dokumentation & GitLab-Repo  
  - Übernahme bei Krankheit oder Abwesenheit des Hauptadmins  

---

## 5. Verbesserungsmöglichkeiten

- **Langfristig:** Integration in ein Monitoring-System wie **CloudWatch** (mit Alarmen für fehlgeschlagene Backups).  
- **Sicherheit:** Aktivierung von **MFA (Multi-Factor Authentication)** für kritische IAM-User.  
- **Kostenoptimierung:** Automatisches Löschen alter AMIs und Snapshots > 90 Tage.  

---

## 6. Fazit

Durch regelmässige Wartung, Monitoring und klare Rollenverteilung ist sichergestellt, dass die Schule im Ernstfall innerhalb weniger Stunden wieder arbeitsfähig ist.  
Die Dokumentation (GitLab) stellt sicher, dass das System auch von Vertretungen zuverlässig betrieben werden kann.

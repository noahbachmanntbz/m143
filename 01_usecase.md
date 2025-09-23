# 01 – Use Case & Anforderungen

Dieses Dokument beschreibt den Anwendungsfall (Use Case) sowie die funktionalen und nicht-funktionalen Anforderungen an das Backup- und Restore-System.

---

## 🎯 Use Case – Schule

Als **Schul-IT-Administrator** möchte ich die Daten der **Schülerverwaltung (RDS MySQL)** sowie die Konfiguration und Daten der **Schul-EC2-Instanz** regelmäßig sichern,  
damit die Schule bei Systemausfällen oder Datenverlust den Betrieb schnell wieder aufnehmen kann.

---

## 📌 Anforderungen

### Funktionale Anforderungen
1. **Datei-Backup (EC2):**  
   - Tägliches Backup der Konfigurations- und Anwendungsdaten  
   - Speicherung in S3  

2. **System-Backup (EC2 AMI):**  
   - Wöchentliche Erstellung eines Images (AMI)  
   - Speicherung in EC2 AMIs  

3. **Datenbank-Backup (RDS):**  
   - Tägliche Dumps der Datenbank `school` in S3  
   - Zusätzliche tägliche RDS-Snapshots  

4. **Monitoring & Reporting:**  
   - Speicherung von Logs in `/var/backups/logs`  
   - E-Mail-Benachrichtigung bei Erfolg/Fehlschlag  

5. **Restore-Szenarien:**  
   - Wiederherstellung einzelner Dateien  
   - Rückspielen kompletter Backups  
   - Wiederherstellung von RDS-Snapshots und EC2-AMIs  

---

### Nicht-funktionale Anforderungen
- **Sicherheit:**  
  - Verschlüsselung aller Daten in S3 (SSE-S3)  
  - Kein Public Access auf RDS  
  - Zugriff nur über IAM-Rollen und Security Groups  

- **Rechtliche Vorgaben:**  
  - Einhaltung von **DSG/DSGVO** (Schülerdaten = besonders schützenswert)  
  - Datensparsamkeit durch automatische Löschung nach 90 Tagen  

- **Performance:**  
  - **RTO ≤ 2 Stunden**  
  - **RPO ≤ 24 Stunden**  

- **Kosten:**  
  - Nutzung von AWS Learner Lab (Budget max. 50 $)  
  - Effiziente Speicherung durch Lifecycle-Regeln (S3 → Glacier)  

---

✅ Mit diesem Use Case ist sichergestellt, dass die Schule vor Datenverlust geschützt ist und bei Ausfällen schnell weiterarbeiten kann.

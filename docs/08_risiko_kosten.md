# Risiko- & Kostenanalyse

## Risiken im Schul-IT-Kontext

### 1. Technische Risiken
- **Hardware- oder Infrastruktur-Ausfall (z. B. EC2 oder RDS Ausfall)**  
  - Eintrittswahrscheinlichkeit: mittel  
  - Auswirkung: hoch → Ausfall des Schulsystems, kein Zugriff auf Noten/Absenzen  
  - Maßnahme: Nutzung von **S3**, **Snapshots**, **AMIs** zur schnellen Wiederherstellung  

- **Fehlkonfiguration von Backups (z. B. falscher Cronjob)**  
  - Eintrittswahrscheinlichkeit: mittel  
  - Auswirkung: hoch → Backups fehlen im Ernstfall  
  - Maßnahme: **Testprotokolle**, regelmäßige Restore-Tests, Monitoring mit Logs und Mails  

- **Speicherkorruption / Datenverlust**  
  - Eintrittswahrscheinlichkeit: gering  
  - Auswirkung: hoch → Verlust sensibler Schülerdaten  
  - Maßnahme: **S3-Objektversionierung**, **Glacier Archivierung**  

---

### 2. Menschliche Risiken
- **Fehlerhafte Eingaben durch Administrator:innen**  
  - Eintrittswahrscheinlichkeit: hoch  
  - Auswirkung: mittel → z. B. Löschen der falschen DB  
  - Maßnahme: Schulung, IAM-Policies mit **Least Privilege**  

- **Unwissenheit oder fehlende Dokumentation**  
  - Eintrittswahrscheinlichkeit: mittel  
  - Auswirkung: hoch → im Notfall keine schnelle Wiederherstellung  
  - Maßnahme: Klare **Restore-Anleitungen**, Ablage in GitLab  

---

### 3. Sicherheitsrisiken
- **Unbefugter Zugriff (Hackerangriff, Missbrauch von Zugangsdaten)**  
  - Eintrittswahrscheinlichkeit: mittel  
  - Auswirkung: sehr hoch → Datenleck von Schülerdaten (DSGVO-Verstoß)  
  - Maßnahme: **IAM-Rollen**, **Multi-Faktor-Auth**, **Verschlüsselung**  

- **Ransomware oder Schadsoftware**  
  - Eintrittswahrscheinlichkeit: gering-mittel  
  - Auswirkung: sehr hoch → Verschlüsselung der produktiven Daten  
  - Maßnahme: Backups **offline** in S3/Glacier, Datenintegrität durch Checksums  

---

### 4. Rechtliche Risiken (DSGVO / DSG)
- **Nichteinhaltung der Löschfristen**  
  - Eintrittswahrscheinlichkeit: gering  
  - Auswirkung: hoch → Bußgelder, rechtliche Konsequenzen  
  - Maßnahme: **Lifecycle-Policy** (90 Tage), automatische Löschung  

- **Unzureichende Transparenz**  
  - Eintrittswahrscheinlichkeit: mittel  
  - Auswirkung: mittel → Beschwerden von Eltern/Schüler:innen  
  - Maßnahme: Dokumentation, Auskunft über gesicherte Daten  

---

## Kostenanalyse (Stand: September 2025, Forecast)

### Fixkosten (monatlich)
- **EC2 (t3.micro, 24/7)**: ca. **0,50 $**  
- **RDS (db.t3.micro, 24/7)**: ca. **6,50 $**  
- **VPC & Netzwerkkosten:** <0,10 $  

### Variable Kosten (abhängig von Datenmenge)
- **S3 Standard (bis 30 Tage):** ca. 0,023 $ pro GB/Monat  
  → Bei ~5 GB Backupdaten = **0,12 $**  
- **S3 Glacier (30–90 Tage):** ca. 0,004 $ pro GB/Monat  
  → Bei ~10 GB Archiv = **0,04 $**  
- **Egress-Kosten (Download im Restore-Fall):** 0,09 $ pro GB  

### Gesamtkosten (geschätzt)
- **Monatlich:** ca. **7–8 $**  
- **Jährlich:** ca. **85–95 $**  

---

## Bewertung
- **Budget:** Passt in das 50 $ Guthaben des AWS Learner Labs (Projektzeitraum < 2 Monate).  
- **Sicherheit:** Risiko von Datenverlust wird stark reduziert (Redundanz, Verschlüsselung, Versionierung).  
- **Wirtschaftlichkeit:** Sehr kostengünstig, da AWS-Dienste nur im kleinen Maßstab genutzt werden.  
- **Rest-Risiko:** bleibt bei menschlichen Fehlern und Cyberangriffen, aber Maßnahmen reduzieren den Schaden.
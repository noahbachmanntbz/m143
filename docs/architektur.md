# 📊 Architekturübersicht

Die Architektur des Backup- und Restore-Systems basiert auf AWS-Diensten und ist speziell für den Einsatz im **Schulbereich** ausgelegt.  
Sie zeigt den gesamten Ablauf von Backups, Speicherung und Monitoring.

## Übersicht
- **EC2-Instanz**: Führt Backup-Skripte und Cronjobs aus  
- **RDS MySQL (School-DB)**: Enthält die Schülerdaten  
- **S3 Bucket**: Zentrales Backup-Repository (mit Lifecycle-Regeln)  
- **S3 Glacier**: Langzeitarchiv für bis zu 90 Tage  
- **Mail-Benachrichtigung (Gmail)**: Meldet Erfolg oder Fehler  
- **Admin (SSH/Monitoring)**: Greift auf EC2 und Logs zu  

## 📊 Architektur-Diagramm
![Architekturübersicht](docs/img/architektur.png)
  

---

# 🔁 Restore-Szenarien

Die Restore-Szenarien beschreiben, wie nach einem Ausfall oder Fehler Daten wiederhergestellt werden können.

1. **Einzelne Datei / Schülerakte** aus S3 wiederherstellen  
2. **Noten-DB** mit SQL-Dump zurückspielen  
3. **EC2 Wiederherstellung**: neue Instanz aus AMI starten  
4. **RDS Wiederherstellung**: Snapshot zurückspielen  
5. **DB-Dump Restore**: Dump von S3 nach MySQL importieren  

## 🔁 Restore-Diagramm
![Restore Übersicht](docs/img/restore.png)
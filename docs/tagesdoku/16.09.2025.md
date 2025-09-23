# Tagesdokumentation -- 16.09.2025

## ✅ Aufgaben heute

-   Aufräumen der Backup-VM
    -   Überprüfung aller Backup-Skripte mit `find`
    -   Alte und doppelte Skripte identifiziert (`backup.env`,
        `/opt/m143/backup.sh`)
    -   Archiv-Verzeichnis `/opt/archive_2025-09-16/` erstellt
    -   Alte Dateien ins Archiv verschoben
-   Kontrolle der aktiven Skripte
    -   Behalten:
        -   `/opt/backup/daily_backup.sh` (tägliche Dateibackups nach
            S3)\
        -   `/opt/backup/weekly_image.sh` (AMI-Backups der EC2)\
        -   `/opt/backup/rds_backup.sh` (RDS-Snapshots)\
        -   `/opt/m143/sendmail.py` (Mail-Versand)\
    -   Überprüfung der Dateirechte (`chmod +x`)
-   Testlauf durchgeführt
    -   `daily_backup.sh` → Backup erstellt und erfolgreich nach S3
        hochgeladen\
    -   `weekly_image.sh` → Funktionierte muss aber noch einige Dinge angepasst werden da noch nciht alles zu 100% stimmt auch wenn die Mail versendet wurde

## 📌 Nächste Schritte

-   `weekly_image.sh` hat auch funktioniert aber noch nicht zu 100 % es müssen noch einige anpassungen vorgenommen werden
-   `rds_backup.sh` testen (Dump + Snapshot der Datenbank *school*)\
-   Restore-Test mit den Daten aus S3 oder Snapshot durchführen

# 05 – Restore-Anleitungen

Dieses Dokument beschreibt die Wiederherstellungsszenarien für das Backup-System.

---

## 1. Einzelne Datei wiederherstellen

**Fall:** Eine bestimmte Konfigurations- oder Nutzerdaten-Datei wurde gelöscht oder überschrieben.  

**Schritte:**
1. AWS Console → S3 → Bucket `backup-raw-bachmann-pe24c`
2. Ordner `backups/files/<Datum>` öffnen
3. Gewünschte Datei (`.tar.gz`) herunterladen
4. Auf EC2 entpacken:
   ```bash
   tar -xvzf <datei>.tar.gz -C /
   ```
5. Prüfen, ob die Datei korrekt wiederhergestellt wurde

---

## 2. Gesamtes File-Backup einspielen

**Fall:** Mehrere oder alle Konfigurationsdateien müssen zurückgesetzt werden.  

**Schritte:**
1. Letztes vollständiges Backup aus S3 herunterladen
2. Auf EC2 entpacken:
   ```bash
   tar -xvzf files-<Datum>.tar.gz -C /
   ```
3. Dienste neustarten:
   ```bash
   sudo systemctl restart <dienstname>
   ```

---

## 3. EC2-Wiederherstellung (AMI)

**Fall:** Die gesamte VM ist ausgefallen.  

**Schritte:**
1. AWS Console → **EC2 → AMIs** → `m143-ami-<Datum>` auswählen
2. Neue Instanz aus dem AMI starten  
   - Instanz-Typ: `t3.micro`  
   - Security Groups: identisch zur alten Instanz  
3. Verbindung per SSH testen:
   ```bash
   ssh ec2-user@<public-ip>
   ```

---

## 4. RDS-Wiederherstellung (Snapshot)

**Fall:** Die Datenbank enthält fehlerhafte Daten.  

**Schritte:**
1. AWS Console → **RDS → Snapshots**
2. Snapshot auswählen (z. B. `school-2025-09-16`) → *Restore Snapshot*
3. Neue DB-Instanz erstellen lassen (`school-restore`)
4. Anwendung auf den neuen Endpoint umstellen

---

## 5. Datenbank-Dump einspielen

**Fall:** Ein gezielter Import einer bestimmten DB-Version ist nötig.  

**Schritte:**
1. Dump aus S3 herunterladen:
   ```bash
   aws s3 cp s3://backup-raw-bachmann-pe24c/backups/db/school/school-<Datum>.sql.gz .
   ```
2. Entpacken:
   ```bash
   gunzip school-<Datum>.sql.gz
   ```
3. In MySQL importieren:
   ```bash
   mysql -h <endpoint> -u <user> -p school < school-<Datum>.sql
   ```

---

Mit diesen Anleitungen lassen sich alle relevanten Systeme (Dateien, EC2, RDS und Datenbank) zuverlässig wiederherstellen.
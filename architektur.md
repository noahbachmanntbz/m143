```mermaid
flowchart TD
    subgraph AWS Cloud
        EC2["EC2 Instanz<br>(Backup-Skripte + Cronjobs)"]
        RDS["RDS MySQL<br>(School-DB)"]
        S3["S3 Bucket<br>(Backups, Lifecycle)"]
    end

    User["Schul-Admin<br>(SSH, Monitoring)"] --> EC2
    EC2 -->|mysqldump + Snapshots| RDS
    EC2 -->|Datei- & DB-Backups| S3
    S3 -->|Lifecycle: 30d→Glacier, 90d→Löschung| Glacier["S3 Glacier"]
    EC2 -->|Fehler/OK Reports| Mail["Mail-Benachrichtigung (Gmail)"]

    style AWS Cloud fill:#f9f9f9,stroke:#bbb,stroke-width:1px

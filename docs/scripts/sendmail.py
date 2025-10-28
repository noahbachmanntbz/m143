#!/usr/bin/env python3
import smtplib
import ssl
import pathlib
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Absender/Empfänger: anpassen (kann gleich sein)
SENDER = "bachmannnoah70@gmail.com"
RECIP  = "bachmannnoah70@gmail.com"

# Passwort-Datei mit Gmail App-Passwort (nur 16 Zeichen, sonst nichts)
PASS_FILE = pathlib.Path("/opt/m143/.mailpass")

def send_mail(subject: str, body: str):
    if not PASS_FILE.exists():
        raise RuntimeError(f"Password file not found: {PASS_FILE}")
    password = PASS_FILE.read_text().strip()

    msg = MIMEMultipart()
    msg["From"] = SENDER
    msg["To"] = RECIP
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    ctx = ssl.create_default_context()
    with smtplib.SMTP("smtp.gmail.com", 587, timeout=30) as srv:
        srv.starttls(context=ctx)
        srv.login(SENDER, password)
        srv.sendmail(SENDER, [RECIP], msg.as_string())

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: sendmail.py <subject> <message>")
        sys.exit(1)
    send_mail(sys.argv[1], sys.argv[2])

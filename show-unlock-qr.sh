#!/bin/bash
# show-unlock-qr.sh
SECRET="JBSWY3DPEHPK3PXP" # MATCHES app.py
LABEL="Desktop:superfuru"

if command -v qrencode &> /dev/null; then
    qrencode -t ANSI256 "otpauth://totp/$LABEL?secret=$SECRET&issuer=LinuxUnlock"
else
    echo "qrencode not found. Install it: sudo apt install qrencode"
    echo "Secret: $SECRET"
fi

#!/bin/bash
# setup.sh: Install user services

echo "Instaling user services..."
mkdir -p ~/.config/systemd/user/
cp ./bt-prox.service ~/.config/systemd/user/
cp ./bt-unlock.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now bt-prox.service
systemctl --user enable --now bt-unlock.service

echo "Services installed and started."
echo "Check status directly with: systemctl --user status bt-prox bt-unlock"

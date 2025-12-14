# EMPIRE RULES – HARDENED EDITION
1. Always start with a numbered plan
2. Every task ends with: DONE – description
3. After every task ask: “Next?”
4. If user says yes/Enter → continue silently
5. If user says stop/change → ask “What should I change?”
6. All progress → .empire_log.md
7. NEVER use subprocess/os.system/run with raw user input
8. ALL web content goes through safe_read_url() wrapper ONLY
9. Prefer qwen2.5:7b → llama3.1 → mistral
10. Every script must end with: chmod +x filename.sh



# Bluetooth Proximity + TOTP Fallback Unlock – Work Plan

## Goals
- Use this pam-bt module to allow proximity unlock with your Galaxy S21.
- Add a robust fallback: LAN-only HTTPS endpoint that verifies a TOTP from Vaultwarden and unlocks the session.
- Provide operator safety: keep password login intact, require phone unlock to send codes, and firewall scope to home LAN.

## Plan
1) **Build the PAM module**
   - Edit `pam_bluetooth.c` line 16 to set `#define MAC "REPLACE-WITH-YOUR-MAC"`.
   - Install deps: `sudo apt update && sudo apt install -y build-essential libbluetooth-dev libpam0g-dev libglib2.0-dev libdbus-1-dev pkg-config git`.
   - Build/install: `gcc -fPIC -fno-stack-protector -c pam_bluetooth.c && sudo ld -x --shared -o /lib/security/pam_bluetooth.so pam_bluetooth.o && sudo ldconfig`.
   - Verify: `ls -l /lib/security/pam_bluetooth.so`.

2) **Pair and trust the phone**
   - `bluetoothctl`: `power on`, `agent KeyboardOnly`, `default-agent`, `scan on` (note MAC), `pair <MAC>`, `trust <MAC>`, `connect <MAC>`, `quit`.
   - Test presence: `bluetoothctl info <MAC>` shows `Connected: yes` when nearby.

3) **Integrate with PAM**
   - In `/etc/pam.d/cinnamon-screensaver` and `/etc/pam.d/lightdm`, after `@include common-auth`, add: `auth sufficient pam_bluetooth.so`.
   - Keep existing password lines so it falls back to password when BT fails.

4) **Keep BT link warm and sync lock state**
   - Create `~/.local/bin/bt-prox.sh` to auto-connect to the MAC every few seconds and call `loginctl unlock-session` when it reconnects.
   - Add user service `~/.config/systemd/user/bt-prox.service`, enable/start with `systemctl --user enable --now bt-prox.service`.

5) **TOTP secret generation and storage**
   - Generate 160-bit secret: `head -c 20 /dev/urandom | base32 | tr -d '='` → `YOURSECRET`.
   - In Vaultwarden: item “Linux Desktop Unlock” with TOTP = `YOURSECRET`; set Bitwarden to auto-lock + biometrics, disable TOTP notifications.
   - Store locally for oathtool: `echo "HOTP/T30/6 $USER - YOURSECRET" | sudo tee /etc/oath-linux-unlock >/dev/null && sudo chmod 600 /etc/oath-linux-unlock`.

6) **Fallback unlock server (HTTPS + TOTP)**
   - Create `~/bt-unlock`, venv, self-signed cert; `app.py` with TOTP check and rate limit (LAN bind `0.0.0.0`, port 7878).
   - User service `~/.config/systemd/user/bt-unlock.service`; enable/start with `systemctl --user enable --now bt-unlock.service`.
   - Firewall LAN-only: `sudo ufw allow from <your LAN CIDR> to any port 7878 proto tcp`.

7) **QR display and shortcut**
   - Script `~/.local/bin/show-unlock-qr.sh` uses `oathtool` + `qrencode` to show current code full screen (`feh -F`).
   - Bind to a keyboard shortcut (e.g., Super+U) in Cinnamon.

8) **Phone-side trigger**
   - HTTP Shortcuts app: POST to `https://desktop.local:7878/unlock`, form field `code` = clipboard text; protect the shortcut with auth/confirm.
   - Workflow: copy TOTP in Bitwarden (requires phone unlock), tap shortcut; PC unlocks.

9) **Testing and tuning**
   - Nearby: lock session; confirm auto-unlock without password.
   - Out of range: ensure it stays locked; test QR + phone flow unlocks. Adjust `strength` not available in this module—physical proximity relies on pairing and signal; consider moving to a richer module later if needed.
   - Check logs: `/var/log/auth.log` (PAM), `journalctl --user -u bt-prox`, `journalctl --user -u bt-unlock`.

10) **Hardening notes**
    - Keep LAN-only firewall; no router port-forwarding.
    - Ensure `/lib/security/pam_bluetooth.so` is root-owned and 644; `/etc/oath-linux-unlock` is 600.
    - Optional: install the self-signed cert as a CA on the phone to avoid MITM inside LAN.

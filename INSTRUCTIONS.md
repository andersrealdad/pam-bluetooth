# Bluetooth Unlock Installation Instructions

Detailed steps to complete the installation of your Bluetooth Proximity Unlock system.

## 1. Install Dependencies & Build PAM Module (Root Required)
Copy and run this entire block in your terminal:
```bash
sudo apt update && sudo apt install -y build-essential libbluetooth-dev libpam0g-dev libglib2.0-dev libdbus-1-dev pkg-config git qrencode
cd ~/pam-bluetooth
gcc -fPIC -fno-stack-protector -c pam_bluetooth.c
sudo ld -x --shared -o /usr/lib/x86_64-linux-gnu/security/pam_bluetooth.so pam_bluetooth.o
sudo ldconfig
```

## 2. Install User Services
Run the helper script I created to set up the background services:
```bash
cd ~/pam-bluetooth
./setup.sh
```

## 3. Configure PAM (Critical)
You need to edit the authentication configuration file.
**Warning**: Be careful not to delete the existing lines, just add the new one.

```bash
sudo nano /etc/pam.d/cinnamon-screensaver
```
*(Note: If you use a different desktop like GNOME, it might be `/etc/pam.d/gdm-password` or just `/etc/pam.d/login`)*

Add this line **at the very top** or right before `@include common-auth`:
```
auth sufficient pam_bluetooth.so
```
Save with `Ctrl+O`, Enter, then Exit with `Ctrl+X`.

## 4. Pair Your Phone & Test
1.  **Pair Bluetooth**: Make sure your phone is paired and trusted with this computer.
2.  **Get TOTP Code**: Run `./show-unlock-qr.sh` to see the QR code. Scan it with your Authenticator app (e.g., Google Authenticator, Authy, Bitwarden).
3.  **Setup Phone Shortcut**: Create an HTTP Shortcut on your Android phone:
    -   **Method**: POST
    -   **URL**: `https://<YOUR_PC_IP>:7878/unlock`
    -   **Body/Params**: Key `code`, Value `(paste code from authenticator)` (Or better, use a variable if your app supports it).

## 5. Firewall (Optional)
If you have a firewall enabled (`ufw`), allow the unlock port:
```bash
sudo ufw allow 7878/tcp
```

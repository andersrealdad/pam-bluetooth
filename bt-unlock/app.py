import pyotp
import subprocess
import os
from flask import Flask, request, abort

app = Flask(__name__)

# CONFIGURATION
# Generate a secret: head -c 20 /dev/urandom | base32 | tr -d '='
# For this demo, I will use a placeholder. User needs to replace this!
# PROD: Read from a secure file or env var
SECRET = "JBSWY3DPEHPK3PXP" # EXAMPLE SECRET - CHANGE ME

@app.route('/unlock', methods=['POST'])
def unlock():
    code = request.form.get('code')
    if not code:
        abort(400)

    totp = pyotp.TOTP(SECRET)
    if totp.verify(code, valid_window=1): # Allow slight skew
        # Valid TOTP, unlock session
        subprocess.run(['loginctl', 'unlock-session'])
        return "Unlocked", 200
    else:
        return "Invalid Code", 403

if __name__ == '__main__':
    # SSL Context for HTTPS (Self-signed)
    # Generate: openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365
    user_dir = os.path.expanduser("~/pam-bluetooth/bt-unlock")
    cert = os.path.join(user_dir, "cert.pem")
    key = os.path.join(user_dir, "key.pem")
    
    if os.path.exists(cert) and os.path.exists(key):
        app.run(host='0.0.0.0', port=7878, ssl_context=(cert, key))
    else:
        print("SSL Certs not found. Running HTTP (INSECURE) for testing.")
        app.run(host='0.0.0.0', port=7878)

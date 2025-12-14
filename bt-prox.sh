#!/bin/bash
# bt-prox.sh: Keep Bluetooth connection warm and unlock on connect
MAC="78:46:D4:98:FA:DC"

while true; do
    # Try to connect
    bluetoothctl connect $MAC >/dev/null 2>&1
    
    # Check if connected
    if bluetoothctl info $MAC | grep -q "Connected: yes"; then
        # If we just connected (implied by previous loop failing or just periodic check), ensure unlocked
        # We rely on the PAM module for the actual auth decision at the screen lock 
        # BUT the plan says: "call loginctl unlock-session when it reconnects"
        
        # Check if session is locked before trying to unlock to avoid spam? 
        # cinnamon-screensaver-command -q could work, but loginctl is generic
        # loginctl unlock-session # DISABLED: Waiting for NFC/Phone trigger
        
        # Sleep a bit longer if connected to avoid busy loop
        sleep 10
    else
        # Not connected, try again soon
        sleep 5
    fi
done

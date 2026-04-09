#!/bin/bash

# Cache sudo password upfront so background processes don't prompt
echo "[*] Enter sudo password once:"
sudo -v

echo "[*] Starting SIEM..."
sudo venv/bin/python -u siem.py &
SIEM_PID=$!

sleep 2  # give Flask time to boot

echo "[*] Starting Capture..."
sudo venv/bin/python capture.py &
CAPTURE_PID=$!

echo "[*] Both running. SIEM PID: $SIEM_PID | Capture PID: $CAPTURE_PID"
echo "[*] Press Ctrl+C to stop both."

# Kill both on Ctrl+C
trap "echo '[*] Stopping...'; kill $SIEM_PID $CAPTURE_PID; exit 0" SIGINT SIGTERM

wait

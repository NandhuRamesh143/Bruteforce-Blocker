import re
import subprocess
import time
from collections import defaultdict
import os
import requests
import threading

SIEM_ENDPOINT = "http://[::1]:5000/alert"
LOG_FILE = "collected_logs.txt"
THRESHOLD = 5

failed_attempts = defaultdict(int)
blocked_ips = set()

pattern = re.compile(r"Failed password.*from ([\da-fA-F\.:]+)")

def unblock_ip(ip, delay=300):  # 300s = 5 minutes
    def _unblock():
        time.sleep(delay)
        try:
            subprocess.run(
                ["sudo", "iptables", "-D", "INPUT", "-s", ip, "-j", "DROP"],
                check=True
            )
            blocked_ips.discard(ip)
            failed_attempts[ip] = 0
            print(f"[UNBLOCKED] {ip} after {delay}s")
        except subprocess.CalledProcessError:
            print(f"[ERROR] Failed to unblock {ip}")
    threading.Thread(target=_unblock, daemon=True).start()
def get_severity(attempts):
    if attempts >= 10:
        return "critical"
    elif attempts >= 7:
        return "high"
    elif attempts >= 4:
        return "medium"
    else:
        return "low"

# Track last fetch time to avoid re-processing old lines
last_fetch_time = None

def send_to_siem(alert):
    try:
        requests.post(SIEM_ENDPOINT, json=alert, timeout=2)
    except Exception as e:
        print("[SIEM ERROR]", e)

def block_ip(ip):
    if ip in ["127.0.0.1", "::1"]:
        print(f"[SKIP] Not blocking local IP {ip}")
        return

    if ip in blocked_ips:
        return

    print(f"[BLOCKING] {ip}")

    try:
        subprocess.run(
            ["sudo", "iptables", "-A", "INPUT", "-s", ip, "-j", "DROP"],
            check=True
        )
        blocked_ips.add(ip)
        unblock_ip(ip, delay=300)
        print(f"[BLOCKED] {ip} added to iptables")
    except subprocess.CalledProcessError:
        print(f"[ERROR] Failed to block {ip}")

def fetch_logs():
    global last_fetch_time

    if last_fetch_time is None:
        # First run: grab last 5 minutes to avoid reprocessing old history
        args = ["journalctl", "-u", "sshd", "--since", "-5min", "--no-pager"]
    else:
        args = ["journalctl", "-u", "sshd", "--since", last_fetch_time, "--no-pager"]

    # Update timestamp before fetching so we don't miss lines at boundary
    last_fetch_time = time.strftime("%Y-%m-%d %H:%M:%S")

    result = subprocess.run(args, capture_output=True, text=True)
    return result.stdout.splitlines()

def save_logs(lines):
    if not lines:
        return
    with open(LOG_FILE, "a") as f:
        for line in lines:
            f.write(line + "\n")

def analyze_lines(lines):
    for line in lines:
        match = pattern.search(line)
        if match:
            ip = match.group(1)

            # Don't keep counting after already blocked
            if ip in blocked_ips:
                continue

            failed_attempts[ip] += 1
            print(f"[ATTEMPT] {ip} → {failed_attempts[ip]} failed attempts")

            if failed_attempts[ip] >= THRESHOLD:
                severity = get_severity(failed_attempts[ip])

                alert = {
                    "type": "brute_force",
                    "ip": ip,
                    "attempts": failed_attempts[ip],
                    "severity": severity,
                    "time": time.strftime("%Y-%m-%d %H:%M:%S")
                }

                print(f"[ALERT] {alert}")

                if severity == "critical":
                    send_to_siem(alert)
                    block_ip(ip)
                elif severity == "high":
                    send_to_siem(alert)
                    block_ip(ip)
                elif severity == "medium":
                    send_to_siem(alert)  # log only, no block
                elif severity == "low":
                    print(f"[LOW] {ip} - monitoring only")

def main():
    if not os.path.exists(LOG_FILE):
        open(LOG_FILE, "w").close()

    print("[STARTING MONITOR]")

    while True:
        lines = fetch_logs()
        save_logs(lines)       # only saves new lines from this window
        analyze_lines(lines)
        time.sleep(5)

if __name__ == "__main__":
    main()

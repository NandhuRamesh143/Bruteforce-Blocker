# 🛡️ Brute Force Blocker

A lightweight SSH brute force detection and auto-blocking tool for Linux. It monitors your SSH logs in real time, detects attackers, automatically bans their IP using `iptables`, and forwards alerts to a local SIEM receiver.

---

## 📸 How It Works

```
SSH Logs (journalctl)
        ↓
  capture.py monitors logs every 5 seconds
        ↓
  Failed login attempts counted per IP
        ↓
  Threshold hit → severity assigned
        ↓
  ┌─────────────────────────────────┐
  │  medium  → alert sent to SIEM  │
  │  high    → alert + IP banned   │
  │  critical→ alert + IP banned   │
  └─────────────────────────────────┘
        ↓
  siem.py receives and logs the alert
        ↓
  IP auto-unbanned after 5 minutes
```

---

## 📁 Project Structure

```
brute-force-blocker/
│
├── capture.py       # Main monitor - reads SSH logs, detects attacks, bans IPs
├── siem.py          # SIEM receiver - Flask server that receives and logs alerts
├── setup.sh         # One-time setup script - installs all dependencies
├── start.sh         # Runs both capture.py and siem.py together
└── README.md        # You are here
```

---

## ⚙️ Requirements

- Linux (any distro)
- Python 3.3+
- `sshd` running and logging via `journalctl`
- `sudo` access (needed for iptables)

---

## 🚀 Installation

**1. Clone the repo**
```bash
git clone https://github.com/NandhuRamesh143/Bruteforce-Blocker.git
cd Bruteforce-Blocker
```

**2. Run the setup script (installs everything)**
```bash
chmod +x setup.sh
bash setup.sh
```

This will automatically install Python, pip, iptables (if missing) and set up a virtual environment with Flask and requests. Works on:

| Distro | Package Manager |
|--------|----------------|
| Ubuntu / Debian / Kali | apt |
| Fedora / RHEL | dnf |
| CentOS (older) | yum |
| Arch / Manjaro | pacman |
| openSUSE | zypper |

---

## ▶️ Running

```bash
chmod +x run.sh
bash run.sh
```

This starts both `siem.py` and `capture.py` together. Press `Ctrl+C` to stop both cleanly.

---

## 🔍 What You'll See
When you run bash run.sh everything appears in one terminal:
```bash
[*] Enter sudo password once:
[*] Starting SIEM...
 * Serving Flask app 'siem'
 * Debug mode: off
[*] Starting Capture...
[*] Both running. SIEM PID: 1234 | Capture PID: 5678
[*] Press Ctrl+C to stop both.
[STARTING MONITOR]
[ATTEMPT] 192.168.1.45 → 1 failed attempts
[ATTEMPT] 192.168.1.45 → 2 failed attempts
[ATTEMPT] 192.168.1.45 → 3 failed attempts
[ALERT] {'type': 'brute_force', 'ip': '192.168.1.45', 'attempts': 7, 'severity': 'high', 'time': '2026-04-09 00:05:35'}
SIEM RECEIVED: {'type': 'brute_force', 'ip': '192.168.1.45', 'attempts': 7, 'severity': 'high', 'time': '2026-04-09 00:05:35'}
[BLOCKING] 192.168.1.45
[BLOCKED] 192.168.1.45 added to iptables
[UNBLOCKED] 192.168.1.45 after 300s
```
Alerts are also saved to `siem_alerts.log`. Watch them live with:
```bash
tail -f siem_alerts.log
```

---

## 🚨 Severity Levels

| Attempts | Severity | Action |
|----------|----------|--------|
| 4 – 6    | medium   | Alert sent to SIEM only |
| 7 – 9    | high     | Alert sent + IP banned |
| 10+      | critical | Alert sent + IP banned |
| < 4      | low      | Printed to console only |

---

## ⏱️ IP Ban Duration

Banned IPs are automatically unblocked after **5 minutes** by default. To change this, edit the `delay` value in `capture.py`:

```python
unblock_ip(ip, delay=300)  # 300 seconds = 5 minutes
```

---

## 🔧 Configuration

All config is at the top of `capture.py`:

```python
SIEM_ENDPOINT = "http://[::1]:5000/alert"  # Where to send alerts
LOG_FILE = "collected_logs.txt"             # Where to save raw logs
THRESHOLD = 5                               # Attempts before alerting
```

---

## 📝 Log Files

| File | Contents |
|------|----------|
| `collected_logs.txt` | Raw SSH log lines captured each cycle |
| `siem_alerts.log` | All alerts received by the SIEM |

---

## ⚠️ Notes

- Local IPs (`127.0.0.1`, `::1`) are never banned
- Bans are cleared on reboot unless you run `sudo iptables-save`
- The tool requires `sshd` to log via `systemd` (journalctl). Most modern Linux distros do this by default
- Run with `sudo` or as root for iptables access

---

## 🤝 Contributing

Pull requests are welcome. For major changes, open an issue first to discuss what you'd like to change.

---

## 📜 License

MIT

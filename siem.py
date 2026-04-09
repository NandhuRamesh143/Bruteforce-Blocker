from flask import Flask, request
import logging
import sys
sys.stdout.reconfigure(line_buffering=True)

app = Flask(__name__)

logging.basicConfig(
    filename="siem_alerts.log",
    level=logging.INFO,
    format="%(asctime)s - %(message)s"
)

@app.route('/alert', methods=['POST'])
def receive():
    alert = request.json
    logging.info(f"ALERT: {alert}")
    print("SIEM RECEIVED:", alert,flush =True)
    return "OK"

app.run(host="::", port=5000)  # listens on both IPv4 and IPv6

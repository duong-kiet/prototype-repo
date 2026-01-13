"""
Simple Flask application with basic UI for security pipeline prototype
"""
from flask import Flask, jsonify, render_template_string
import os

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

# Simple HTML template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Pipeline Demo</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: system-ui, -apple-system, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        .status-card {
            background: rgba(255,255,255,0.1);
            border-radius: 16px;
            padding: 3rem 4rem;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        h1 {
            font-size: 2rem;
            margin-bottom: 1rem;
            color: #4ade80;
        }
        .version {
            color: #94a3b8;
            font-size: 0.9rem;
            margin-bottom: 2rem;
        }
        .status {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: #22c55e;
            padding: 0.5rem 1.5rem;
            border-radius: 999px;
            font-weight: 600;
        }
        .dot {
            width: 8px;
            height: 8px;
            background: #fff;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="status-card">
            <h1>🛡️ Security Pipeline Demo</h1>
            <p class="version">Version {{ version }}</p>
            <div class="status">
                <span class="dot"></span>
                Running on AWS
            </div>
        </div>
    </div>
</body>
</html>
"""


@app.route("/")
def home():
    return render_template_string(HTML_TEMPLATE, version=APP_VERSION)


@app.route("/api/health")
def health():
    return jsonify({"status": "ok", "version": APP_VERSION})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))

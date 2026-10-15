"""Session 17 - DevSecOps demo app (tiny Flask API)."""
import os

from flask import Flask, jsonify

app = Flask(__name__)

def message() -> str:
    return "Hello World from Vansh's DevSecOps pipeline!"

@app.get("/")
def index():
    return f"<h1>{message()}</h1><p>Version: {os.getenv('APP_VERSION', 'local')}</p>"

@app.get("/health")
def health():
    return jsonify(status="ok")

if __name__ == "__main__":
    app.run(port=8000)

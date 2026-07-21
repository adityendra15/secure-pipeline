"""Small Flask application used to demonstrate a secure CI/CD pipeline."""

import os

from flask import Flask, jsonify


def create_app() -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)

    @app.get("/")
    def home():
        return jsonify(
            message="Secure pipeline application is running",
            version=os.getenv("APP_VERSION", "development"),
            pod=os.getenv("HOSTNAME", "local"),
        )

    @app.get("/health/live")
    def liveness():
        return jsonify(status="alive"), 200

    @app.get("/health/ready")
    def readiness():
        return jsonify(status="ready"), 200

    # Kept as a compatibility endpoint for the original project.
    @app.get("/healthz")
    def healthz():
        return jsonify(status="ok"), 200

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)

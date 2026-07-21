from app import create_app


def test_home_endpoint():
    client = create_app().test_client()
    response = client.get("/")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["message"] == "Secure pipeline application is running"
    assert "version" in payload
    assert "pod" in payload


def test_liveness_endpoint():
    client = create_app().test_client()
    response = client.get("/health/live")

    assert response.status_code == 200
    assert response.get_json() == {"status": "alive"}


def test_readiness_endpoint():
    client = create_app().test_client()
    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ready"}


def test_compatibility_health_endpoint():
    client = create_app().test_client()
    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}

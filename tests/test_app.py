from app import app


def test_home():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert response.get_json()["application"] == "secure-pipeline"


def test_liveness():
    client = app.test_client()
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.get_json()["status"] == "alive"


def test_readiness():
    client = app.test_client()
    response = client.get("/health/ready")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ready"

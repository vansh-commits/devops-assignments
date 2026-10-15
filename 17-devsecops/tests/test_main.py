from app.main import app, message

def test_message():
    assert "Hello World" in message()

def test_index_page():
    res = app.test_client().get("/")
    assert res.status_code == 200
    assert b"DevSecOps" in res.data

def test_health():
    res = app.test_client().get("/health")
    assert res.status_code == 200
    assert res.get_json() == {"status": "ok"}

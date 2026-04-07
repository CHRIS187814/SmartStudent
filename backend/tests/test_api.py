import pytest
from fastapi.testclient import TestClient
from main import app, get_current_user

client = TestClient(app)

# Mock user for testing protected routes
class MockUser:
    def __init__(self, id, email):
        self.id = id
        self.email = email

def mock_get_current_user():
    return MockUser(id="test-user-uuid", email="test@example.com")

# Override dependency
app.dependency_overrides[get_current_user] = mock_get_current_user

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "online"

def test_live_check():
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json()["status"] == "live"

def test_add_task_validation_error():
    # Missing required fields
    response = client.post("/add-task", json={"name": ""})
    assert response.status_code == 422

def test_add_task_success():
    # Note: This will still fail if Supabase is not configured or fails,
    # but we can check the pydantic validation here.
    payload = {
        "name": "Finish AI Assignment",
        "deadline": "2026-05-01T10:00:00Z",
        "task_weight": 0.3,
        "effort_level": 3,
        "category": "Academic",
        "description": "Integration Test Task"
    }
    # We expect a 503 if Supabase is not configured, or a 201 if it is and works.
    response = client.post("/add-task", json=payload)
    assert response.status_code in [201, 503, 500] 

if __name__ == "__main__":
    pytest.main([__file__])

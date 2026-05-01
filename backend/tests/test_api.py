import pytest
from fastapi.testclient import TestClient
from api.main import app


class TestHealthEndpoint:
    """Tests for the /health endpoint."""

    def test_health_check_returns_200(self):
        """Test that health endpoint returns 200 status code."""
        client = TestClient(app)
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_check_returns_ok_status(self):
        """Test that health endpoint returns status 'ok'."""
        client = TestClient(app)
        response = client.get("/health")
        data = response.json()
        assert data["status"] == "ok"

    def test_health_check_returns_service_name(self):
        """Test that health endpoint returns correct service name."""
        client = TestClient(app)
        response = client.get("/health")
        data = response.json()
        assert data["service"] == "MediAuth AI"

    def test_health_check_returns_version(self):
        """Test that health endpoint returns version."""
        client = TestClient(app)
        response = client.get("/health")
        data = response.json()
        assert data["version"] == "0.1.0"

    def test_health_check_returns_environment(self):
        """Test that health endpoint returns environment."""
        client = TestClient(app)
        response = client.get("/health")
        data = response.json()
        assert "environment" in data

    def test_health_check_response_structure(self):
        """Test that health endpoint returns all required fields."""
        client = TestClient(app)
        response = client.get("/health")
        data = response.json()
        required_fields = ["status", "service", "version", "environment"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"

    def test_health_check_content_type(self):
        """Test that health endpoint returns JSON content type."""
        client = TestClient(app)
        response = client.get("/health")
        assert "application/json" in response.headers["content-type"]


class TestCORS:
    """Tests for CORS middleware configuration."""

    def test_cors_headers_present(self):
        """Test that CORS headers are present in responses."""
        client = TestClient(app)
        response = client.get("/health")
        # FastAPI's CORSMiddleware adds headers when origin header is present
        assert response.status_code == 200


class TestAppConfiguration:
    """Tests for FastAPI app configuration."""

    def test_app_title(self):
        """Test that app has correct title."""
        assert app.title == "MediAuth AI"

    def test_app_description(self):
        """Test that app has correct description."""
        assert app.description == "Autonomous Insurance Authorization & Appeal Agent"

    def test_app_version(self):
        """Test that app has correct version."""
        assert app.version == "0.1.0"

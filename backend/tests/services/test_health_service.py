from app.services.health_service import HealthService


def test_get_health_status():
    health_service = HealthService()

    result = health_service.get_health_status()

    assert result == {"status": "healthy"}
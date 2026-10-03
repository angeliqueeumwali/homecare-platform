class HealthService:
    def get_health_status(self) -> dict:
        return {
            "status": "healthy"
        }


health_service = HealthService()
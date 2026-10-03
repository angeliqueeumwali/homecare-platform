from fastapi import APIRouter

from app.services.health_service import health_service

router = APIRouter()


@router.get("/health")
def get_health():
    return health_service.get_health_status()
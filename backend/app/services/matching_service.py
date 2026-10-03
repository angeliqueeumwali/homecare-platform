from math import radians, sin, cos, sqrt, atan2
from app.core.enums import ProviderApprovalStatus
from app.repositories.provider_repository import ProviderRepository

def calculate_distance_km(lat1, lon1, lat2, lon2):
    earth_radius = 6371.0
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    return earth_radius * 2 * atan2(sqrt(a), sqrt(1 - a))

class MatchingService:
    @staticmethod
    async def find_nearest_providers(db, service_category_id, latitude, longitude):
        providers = await ProviderRepository.get_available_for_service(db, service_category_id)
        matches = []
        for provider in providers:
            if provider.approval_status != ProviderApprovalStatus.APPROVED or not provider.location:
                continue
            distance = calculate_distance_km(
                latitude, longitude,
                float(provider.location.latitude),
                float(provider.location.longitude),
            )
            matches.append({"provider": provider, "distance_km": round(distance, 2)})
        matches.sort(key=lambda x: x["distance_km"])
        return matches

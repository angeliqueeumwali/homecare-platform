import os
import uuid

from fastapi import UploadFile

from app.core.config import settings
from app.models.service_request_image import ServiceRequestImage
from app.repositories.service_request_image_repository import (
    ServiceRequestImageRepository,
)

# Only these types are accepted, and the saved extension is derived from the
# type rather than from the client filename so a file cannot be saved with a
# misleading or executable extension.
ALLOWED_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}

MAGIC_BYTES = (
    (b"\xff\xd8\xff", "image/jpeg"),
    (b"\x89PNG\r\n\x1a\n", "image/png"),
    (b"GIF87a", "image/gif"),
    (b"GIF89a", "image/gif"),
)


def uploads_dir() -> str:
    path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "app",
        "static",
        "uploads",
        "service-requests",
    )
    os.makedirs(path, exist_ok=True)
    return path


def detect_content_type(header: bytes) -> str | None:
    for magic, content_type in MAGIC_BYTES:
        if header.startswith(magic):
            return content_type
    # WebP: "RIFF"...."WEBP"
    if header[:4] == b"RIFF" and header[8:12] == b"WEBP":
        return "image/webp"
    return None


class ServiceRequestImageService:
    @staticmethod
    async def list_for_request(db, request_id):
        return await ServiceRequestImageRepository.get_for_request(db, request_id)

    @staticmethod
    async def upload(db, request_id, file: UploadFile):
        if file.content_type not in ALLOWED_TYPES:
            raise ValueError(
                "Unsupported image type. Allowed types: "
                + ", ".join(sorted(ALLOWED_TYPES))
            )

        existing = await ServiceRequestImageRepository.count_for_request(db, request_id)
        if existing >= settings.max_images_per_request:
            raise ValueError(
                f"A request can have at most {settings.max_images_per_request} images"
            )

        contents = await file.read()
        if not contents:
            raise ValueError("The uploaded file is empty")

        if len(contents) > settings.max_image_upload_bytes:
            raise ValueError(
                f"Image is too large. Maximum size is "
                f"{settings.max_image_upload_bytes // (1024 * 1024)} MB"
            )

        actual_type = detect_content_type(contents[:16])
        if actual_type is None:
            raise ValueError("The uploaded file is not a valid image")
        if actual_type != file.content_type:
            raise ValueError(
                f"File content does not match the declared type "
                f"({file.content_type})"
            )

        extension = ALLOWED_TYPES[actual_type]
        filename = f"{uuid.uuid4().hex}{extension}"
        path = os.path.join(uploads_dir(), filename)

        with open(path, "wb") as handle:
            handle.write(contents)

        try:
            return await ServiceRequestImageRepository.create(
                db,
                ServiceRequestImage(
                    service_request_id=request_id,
                    image_url=f"/static/uploads/service-requests/{filename}",
                    original_filename=(file.filename or "")[:255] or None,
                ),
            )
        except Exception:
            # Never leave an orphaned file behind if the DB write fails.
            if os.path.exists(path):
                os.remove(path)
            raise

    @staticmethod
    async def delete(db, image):
        filename = os.path.basename(image.image_url)
        await ServiceRequestImageRepository.delete(db, image)

        path = os.path.join(uploads_dir(), filename)
        if os.path.exists(path):
            os.remove(path)

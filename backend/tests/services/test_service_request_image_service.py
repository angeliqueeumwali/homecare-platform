import io
import os
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest
from fastapi import UploadFile
from starlette.datastructures import Headers

from app.models.service_request_image import ServiceRequestImage
from app.services import service_request_image_service as module
from app.services.service_request_image_service import (
    ServiceRequestImageService,
    detect_content_type,
)

PNG_HEADER = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32
JPEG_HEADER = b"\xff\xd8\xff\xe0" + b"\x00" * 32
WEBP_HEADER = b"RIFF\x00\x00\x00\x00WEBPVP8 "


def build_upload(name="photo.png", content_type="image/png", data=PNG_HEADER):
    headers = Headers({"content-type": content_type})
    return UploadFile(file=io.BytesIO(data), filename=name, headers=headers)


@pytest.fixture
def uploads_dir(tmp_path):
    with patch.object(module, "uploads_dir", return_value=str(tmp_path)):
        yield tmp_path


@pytest.fixture
def repo():
    with patch(
        "app.services.service_request_image_service.ServiceRequestImageRepository.create",
        new=AsyncMock(),
    ) as create, patch(
        "app.services.service_request_image_service.ServiceRequestImageRepository.get_for_request",
        new=AsyncMock(return_value=[]),
    ) as get_for, patch(
        "app.services.service_request_image_service.ServiceRequestImageRepository.count_for_request",
        new=AsyncMock(return_value=0),
    ) as count, patch(
        "app.services.service_request_image_service.ServiceRequestImageRepository.delete",
        new=AsyncMock(),
    ) as delete:
        yield {
            "create": create,
            "get_for_request": get_for,
            "count": count,
            "delete": delete,
        }


class TestDetectContentType:
    def test_detects_png(self):
        assert detect_content_type(PNG_HEADER) == "image/png"

    def test_detects_jpeg(self):
        assert detect_content_type(JPEG_HEADER) == "image/jpeg"

    def test_detects_webp(self):
        assert detect_content_type(WEBP_HEADER) == "image/webp"

    def test_detects_gif(self):
        assert detect_content_type(b"GIF89a" + b"\x00" * 32) == "image/gif"

    def test_returns_none_for_html(self):
        assert detect_content_type(b"<html><body>hi</body></html>") is None

    def test_returns_none_for_empty(self):
        assert detect_content_type(b"") is None


class TestUpload:
    @pytest.mark.asyncio
    async def test_saves_file_and_returns_record(self, repo, uploads_dir):
        request_id = uuid4()
        repo["create"].return_value = ServiceRequestImage(
            service_request_id=request_id, image_url="/static/x.png"
        )

        result = await ServiceRequestImageService.upload(
            Mock(), request_id, build_upload()
        )

        saved = list(uploads_dir.iterdir())
        assert len(saved) == 1
        assert saved[0].suffix == ".png"
        assert saved[0].read_bytes() == PNG_HEADER

        created = repo["create"].await_args.args[1]
        assert created.image_url.endswith(saved[0].name)
        assert created.image_url.startswith("/static/uploads/service-requests/")
        assert created.service_request_id == request_id
        assert created.original_filename == "photo.png"
        assert result is repo["create"].return_value

    @pytest.mark.asyncio
    async def test_extension_comes_from_content_not_filename(self, repo, uploads_dir):
        request_id = uuid4()
        repo["create"].return_value = ServiceRequestImage(
            service_request_id=request_id, image_url="/static/x"
        )

        await ServiceRequestImageService.upload(
            Mock(),
            request_id,
            build_upload(name="malicious.html", content_type="image/png"),
        )

        saved = list(uploads_dir.iterdir())[0]
        assert saved.suffix == ".png"

    @pytest.mark.asyncio
    async def test_filename_is_unpredictable(self, repo, uploads_dir):
        request_id = uuid4()
        repo["create"].return_value = ServiceRequestImage(
            service_request_id=request_id, image_url="/static/x"
        )

        await ServiceRequestImageService.upload(
            Mock(), request_id, build_upload(name="../../escape.png")
        )

        saved = list(uploads_dir.iterdir())[0]
        # Stored flat inside the uploads dir, not relative to the filename.
        assert saved.parent == uploads_dir
        assert saved.name != "escape.png"

    @pytest.mark.asyncio
    async def test_rejects_disallowed_content_type(self, repo, uploads_dir):
        with pytest.raises(ValueError, match="Unsupported image type"):
            await ServiceRequestImageService.upload(
                Mock(),
                uuid4(),
                build_upload(name="doc.pdf", content_type="application/pdf", data=b"%PDF"),
            )

        repo["create"].assert_not_awaited()
        assert list(uploads_dir.iterdir()) == []

    @pytest.mark.asyncio
    async def test_rejects_non_image_content_declared_as_image(self, repo, uploads_dir):
        with pytest.raises(ValueError, match="not a valid image"):
            await ServiceRequestImageService.upload(
                Mock(),
                uuid4(),
                build_upload(data=b"<html>not an image at all</html>"),
            )

        repo["create"].assert_not_awaited()
        assert list(uploads_dir.iterdir()) == []

    @pytest.mark.asyncio
    async def test_rejects_content_that_contradicts_declared_type(self, repo, uploads_dir):
        with pytest.raises(ValueError, match="does not match the declared type"):
            await ServiceRequestImageService.upload(
                Mock(),
                uuid4(),
                build_upload(content_type="image/png", data=JPEG_HEADER),
            )

        assert list(uploads_dir.iterdir()) == []

    @pytest.mark.asyncio
    async def test_rejects_empty_file(self, repo, uploads_dir):
        with pytest.raises(ValueError, match="empty"):
            await ServiceRequestImageService.upload(
                Mock(), uuid4(), build_upload(data=b"")
            )

    @pytest.mark.asyncio
    async def test_rejects_file_over_size_limit(self, repo, uploads_dir):
        big = PNG_HEADER + b"\x00" * (6 * 1024 * 1024)
        with pytest.raises(ValueError, match="too large"):
            await ServiceRequestImageService.upload(
                Mock(), uuid4(), build_upload(data=big)
            )

        assert list(uploads_dir.iterdir()) == []

    @pytest.mark.asyncio
    async def test_enforces_max_images_per_request(self, repo, uploads_dir):
        repo["count"].return_value = 5
        with pytest.raises(ValueError, match="at most"):
            await ServiceRequestImageService.upload(
                Mock(), uuid4(), build_upload()
            )

        assert list(uploads_dir.iterdir()) == []

    @pytest.mark.asyncio
    async def test_removes_file_when_database_write_fails(self, repo, uploads_dir):
        repo["create"].side_effect = RuntimeError("db down")

        with pytest.raises(RuntimeError):
            await ServiceRequestImageService.upload(
                Mock(), uuid4(), build_upload()
            )

        assert list(uploads_dir.iterdir()) == []


class TestList:
    @pytest.mark.asyncio
    async def test_list_for_request(self, repo):
        request_id = uuid4()
        images = [ServiceRequestImage(service_request_id=request_id, image_url="/a.png")]
        repo["get_for_request"].return_value = images

        result = await ServiceRequestImageService.list_for_request(Mock(), request_id)

        assert result == images
        repo["get_for_request"].assert_awaited_once()


class TestDelete:
    @pytest.mark.asyncio
    async def test_deletes_record_and_file(self, repo, uploads_dir):
        path = uploads_dir / "deadbeef.png"
        path.write_bytes(PNG_HEADER)

        image = ServiceRequestImage(image_url="/static/uploads/service-requests/deadbeef.png")
        await ServiceRequestImageService.delete(Mock(), image)

        repo["delete"].assert_awaited_once()
        assert not os.path.exists(path)

    @pytest.mark.asyncio
    async def test_does_not_delete_outside_uploads_dir(self, repo, uploads_dir):
        image = ServiceRequestImage(image_url="/static/services/housekeeping.jpg")
        await ServiceRequestImageService.delete(Mock(), image)

        # basename() strips any traversal from image_url
        assert os.path.exists(
            os.path.join(
                str(uploads_dir), "housekeeping.jpg"
            )
        ) is False
        repo["delete"].assert_awaited_once()

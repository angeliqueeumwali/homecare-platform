import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    DATABASE_HOST = os.getenv("DATABASE_HOST")
    DATABASE_PORT = os.getenv("DATABASE_PORT")
    DATABASE_NAME = os.getenv("DATABASE_NAME")
    DATABASE_USER = os.getenv("DATABASE_USER")
    DATABASE_PASSWORD = os.getenv("DATABASE_PASSWORD")

    JWT_SECRET_KEY = os.getenv(
        "JWT_SECRET_KEY",
        "development-secret-key",
    )

    JWT_ALGORITHM = os.getenv(
        "JWT_ALGORITHM",
        "HS256",
    )

    JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(
        os.getenv(
            "JWT_ACCESS_TOKEN_EXPIRE_MINUTES",
            "60",
        )
    )

    MAX_IMAGES_PER_REQUEST = int(
        os.getenv(
            "MAX_IMAGES_PER_REQUEST",
            "5",
        )
    )

    MAX_IMAGE_UPLOAD_BYTES = int(
        os.getenv(
            "MAX_IMAGE_UPLOAD_BYTES",
            str(5 * 1024 * 1024),
        )
    )

    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES = int(
        os.getenv("PASSWORD_RESET_TOKEN_EXPIRE_MINUTES", "30")
    )

    PASSWORD_RESET_DEV_RETURN_TOKEN = os.getenv(
        "PASSWORD_RESET_DEV_RETURN_TOKEN",
        "false",
    ).lower() in {"1", "true", "yes"}

    CONTACT_RATE_LIMIT_PER_HOUR = int(
        os.getenv("CONTACT_RATE_LIMIT_PER_HOUR", "5")
    )

    CONTACT_MIN_MESSAGE_LENGTH = int(
        os.getenv("CONTACT_MIN_MESSAGE_LENGTH", "10")
    )

    DATABASE_SSLMODE = os.getenv("DATABASE_SSLMODE", "disable")

    CORS_ALLOWED_ORIGINS = [
        origin.strip()
        for origin in os.getenv(
            "CORS_ALLOWED_ORIGINS",
            "http://localhost:3000,http://localhost:3001",
        ).split(",")
        if origin.strip()
    ]

    @property
    def max_images_per_request(self) -> int:
        return self.MAX_IMAGES_PER_REQUEST

    @property
    def max_image_upload_bytes(self) -> int:
        return self.MAX_IMAGE_UPLOAD_BYTES

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://"
            f"{self.DATABASE_USER}:"
            f"{self.DATABASE_PASSWORD}@"
            f"{self.DATABASE_HOST}:"
            f"{self.DATABASE_PORT}/"
            f"{self.DATABASE_NAME}"
        )


settings = Settings()
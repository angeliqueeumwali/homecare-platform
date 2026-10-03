# Deployment Guide

Pre-deployment requirements for the Homecare Platform. **Nothing is deployed yet.** This document separates what is already configured from what must be configured during deployment, and what is not implemented.

## Repository layout (Git)

The project is versioned as **two separate Git repositories** that must be pushed independently:

- Root repository: `dashboard/`, `website/`, `mobile/`, `docs/`, `README.md`
- `backend/`: independent repository with its own history and remote

## 1. PostgreSQL

- Already configured: Alembic migrations (current head `a94c1e62f7b3`). All migrations are additive and reversible (destructive operations exist only in `downgrade()` functions).
- Create the schema with: `alembic upgrade head`
- Required environment variables (see `backend/.env.example`):
  - `DATABASE_HOST`, `DATABASE_PORT` (default 5432), `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD`
- The backend builds the connection string from these variables (`postgresql+asyncpg://...`); there is no default database URL, so the backend will not start without them.

## 2. FastAPI backend

Already configured:
- JWT authentication (HS256, 60-minute access tokens), role-based access control (CUSTOMER / PROVIDER / ADMIN), input validation, rate-limited contact form (5 requests/hour per IP), comprehensive pytest suite (316 tests).

Environment variables required:
- `JWT_SECRET_KEY` — **must be overridden in production**; the code default (`development-secret-key`) is insecure.
- `JWT_ALGORITHM` (default `HS256`), `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` (default 60)
- `PASSWORD_RESET_TOKEN_EXPIRE_MINUTES` (default 30)
- `PASSWORD_RESET_DEV_RETURN_TOKEN` — must stay `false` (default). When `true`, the password-reset endpoint returns the reset token in the API response, which is a development-only backdoor.
- `MAX_IMAGES_PER_REQUEST` (default 5), `MAX_IMAGE_UPLOAD_BYTES` (default 5 MiB)
- `CONTACT_RATE_LIMIT_PER_HOUR` (default 5), `CONTACT_MIN_MESSAGE_LENGTH` (default 10)

Deployment-specific configuration required:
- **CORS**: `app/main.py` currently sets `allow_origins=["*"]` together with `allow_credentials=True`. Before going live, restrict `allow_origins` to the exact deployed origins of the dashboard and the public website (for example `https://dashboard.example.com` and `https://www.example.com`). Do not ship the wildcard with credentials enabled in production.

Not currently implemented:
- **Email delivery** (SMTP): password-reset and contact-form endpoints persist records and honestly report `email_delivery_configured: false`. Wire an SMTP provider before these emails are needed.
- **Real payment processing**: payments are recorded in the application database only; there is no Stripe/PayPal/Mobile Money gateway integration.
- **Push notifications**: notifications are in-app (database) only; no FCM/APNs.

## 3. Next.js dashboard

- Required environment variable: `NEXT_PUBLIC_API_URL` (backend base URL). Falls back to `http://localhost:8000` when unset — always set it explicitly for production builds.
- Build: `npm ci && npm run build`; serve the built Next.js app behind a production server (e.g. `npm start` or a Node host). Development port is 3001.

## 4. Next.js public website

- Required environment variable: `NEXT_PUBLIC_API_URL` (same backend URL as the dashboard). Same localhost fallback caveat applies.
- Build: `npm ci && npm run build`; serve behind a production server. Development port is 3000.

## 5. Flutter mobile app

- The API base URL is compile-time configuration, not a runtime env file:
  `flutter build apk --dart-define=API_BASE_URL=https://api.example.com`
- Development-only fallbacks in `lib/constants/app_config.dart`: `http://10.0.2.2:8000` (Android emulator) and `http://localhost:8000`. Always pass `API_BASE_URL` for release builds.

## Validation before deployment

- Backend: `pytest` (316 tests)
- Dashboard: `npm test`, `npm run lint`, `npm run build`
- Website: `npm test`, `npm run lint`, `npm run build`
- Mobile: `flutter analyze`, `flutter test`, `flutter build apk`

## Local development seed data

`backend/scripts/seed_acceptance.py` creates local acceptance accounts. Passwords come from the `SEED_ADMIN_PASSWORD`, `SEED_CUSTOMER_PASSWORD`, and `SEED_PROVIDER_PASSWORD` environment variables (see `backend/.env.example`); the built-in fallbacks are development-only values that must **never** be used against a shared, staging, or production database. Do not run the script against any database other than your local development database.

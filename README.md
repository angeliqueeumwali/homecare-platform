# Homecare Platform

A platform that connects customers with homecare service providers.

## Components

- `backend/` — FastAPI + PostgreSQL REST API (independent Git repository with its own history and remote)
- `mobile/` — Flutter app for customers and providers
- `dashboard/` — Next.js admin dashboard
- `website/` — Next.js public website

## Getting started

See `docs/DEPLOYMENT.md` for environment variables, migration, and deployment requirements for each component. See each component's own `README.md` for component-specific notes.

## Features

- Customer registration, login, service requests, quotes, payments, reviews, and issue reporting
- Provider profiles, service listings, assignments, and status updates
- Admin dashboard for users, providers, requests, quotes, payments, reviews, issues, and notifications

## Development

- Backend: Python 3.10+, PostgreSQL, Alembic migrations, pytest
- Dashboard/website: Node.js, Next.js 15 (App Router, JavaScript)
- Mobile: Flutter 3.x, Dart

All test suites and lint/build checks pass before deployment; see `docs/DEPLOYMENT.md` for the commands.

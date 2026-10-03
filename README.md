# Homecare Platform

A platform that connects customers with homecare service providers.

## Components

- `backend/` — FastAPI + PostgreSQL REST API
- `mobile/` — Flutter app for customers and providers
- `dashboard/` — Next.js admin dashboard
- `website/` — Next.js public website

## Getting started

See `docs/DEPLOYMENT.md` for environment variables, migration, and deployment requirements for each component. See each component's own `README.md` for component-specific notes.

## Features

- Customer registration, login, service requests, quotes, payments, reviews, and issue reporting
- Provider profiles, service listings, assignments, and status updates
- Admin dashboard for users, providers, requests, quotes, payments, reviews, issues, and notifications

## Technology

- Flutter and Dart (mobile app)
- Python, FastAPI, PostgreSQL, SQLAlchemy, Alembic (backend)
- Node.js and Next.js 15 (dashboard and public website)

All test suites and lint/build checks pass before deployment; see `docs/DEPLOYMENT.md` for the commands.


# Homecare Platform Backend

This is the backend for my Homecare Platform project. The platform is designed to connect customers with homecare service providers.

I am building this project to practice backend development, database management, authentication, and API testing using FastAPI and PostgreSQL.

## Technologies

- Python
- FastAPI
- PostgreSQL
- SQLAlchemy
- Alembic
- Pydantic
- JWT Authentication
- Pytest
- Postman

## Main Features

- User registration and login
- User profile management
- Provider profiles
- Service categories
- Service requests
- Provider matching
- Assignments
- Quotes
- Payments
- Notifications
- Reviews
- Issue reporting
- Admin management

## Architecture

The backend uses a layered architecture: routers handle HTTP requests, services contain the business logic, repositories manage database access, and models and schemas define the data.

```text
app/
├── core/
├── database/
├── models/
├── repositories/
├── routers/
├── schemas/
└── services/

tests/
├── routers/
├── services/
└── repositories/
```

Authentication uses JWT access tokens with role-based access control (CUSTOMER, SERVICE_PROVIDER, ADMIN).

## Running the Project

The backend lives in the `backend/` directory of the Homecare Platform project.

Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Configure your environment variables in a `.env` file (see `.env.example` for the required variables, including the PostgreSQL connection settings and `JWT_SECRET_KEY`).

Create the database schema:

```bash
alembic upgrade head
```

Start the development server:

```bash
uvicorn app.main:app --reload
```

The API documentation is available at:

```text
http://127.0.0.1:8000/docs
```

## Testing

Run the tests with:

```bash
pytest
```

The test suite includes 316 tests covering the routers, services, and repositories.

## Project Status

The backend is under development. I am continuing to build and test the platform's features.

## Author

Umwali Angelique

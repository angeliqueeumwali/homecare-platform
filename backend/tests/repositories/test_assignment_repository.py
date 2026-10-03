from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.assignment_repository import AssignmentRepository


def db_with_one(value):
    db = MagicMock()
    db.execute = AsyncMock()

    result = MagicMock()
    result.scalar_one_or_none.return_value = value

    db.execute.return_value = result
    return db


def db_with_many(values):
    db = MagicMock()
    db.execute = AsyncMock()

    result = MagicMock()
    result.scalars.return_value.all.return_value = values

    db.execute.return_value = result
    return db


def create_db():
    db = MagicMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.delete = AsyncMock()
    return db


@pytest.mark.asyncio
async def test_create_assignment():
    db = create_db()
    assignment = MagicMock()

    result = await AssignmentRepository.create(db, assignment)

    assert result == assignment
    db.add.assert_called_once_with(assignment)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(assignment)


@pytest.mark.asyncio
async def test_get_assignment_by_id():
    assignment = MagicMock()
    db = db_with_one(assignment)

    result = await AssignmentRepository.get_by_id(db, "assignment-id")

    assert result == assignment
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_assignment_by_id_eager_loads_service_request_relationships():
    db = db_with_one(None)

    await AssignmentRepository.get_by_id(db, "assignment-id")

    statement = db.execute.call_args[0][0]
    options = getattr(statement, "_with_options", ())
    paths = [str(option.path) for option in options]
    assert any("Assignment.service_request ->" in path for path in paths)
    assert any("Assignment.service_request_item ->" in path for path in paths)


@pytest.mark.asyncio
async def test_get_assignment_by_id_returns_none():
    db = db_with_one(None)

    result = await AssignmentRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_provider_assignments():
    assignments = [MagicMock(), MagicMock()]
    db = db_with_many(assignments)

    result = await AssignmentRepository.get_provider_assignments(db, "provider-id")

    assert result == assignments
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_request_assignments():
    assignments = [MagicMock(), MagicMock()]
    db = db_with_many(assignments)

    result = await AssignmentRepository.get_request_assignments(db, "request-id")

    assert result == assignments
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_assignment():
    db = create_db()
    assignment = MagicMock()

    result = await AssignmentRepository.update(db, assignment)

    assert result == assignment
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(assignment)
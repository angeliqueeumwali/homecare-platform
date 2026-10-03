from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.issue_repository import IssueRepository


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
async def test_create_issue():
    db = create_db()
    issue = MagicMock()

    result = await IssueRepository.create(db, issue)

    assert result == issue
    db.add.assert_called_once_with(issue)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(issue)


@pytest.mark.asyncio
async def test_get_issue_by_id():
    issue = MagicMock()
    db = db_with_one(issue)

    result = await IssueRepository.get_by_id(db, "issue-id")

    assert result == issue
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_issue_by_id_returns_none():
    db = db_with_one(None)

    result = await IssueRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_user_issues():
    issues = [MagicMock(), MagicMock()]
    db = db_with_many(issues)

    result = await IssueRepository.get_user_issues(db, "user-id")

    assert result == issues
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_all_issues():
    issues = [MagicMock(), MagicMock()]
    db = db_with_many(issues)

    result = await IssueRepository.get_all(db)

    assert result == issues
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_issue():
    db = create_db()
    issue = MagicMock()

    result = await IssueRepository.update(db, issue)

    assert result == issue
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(issue)
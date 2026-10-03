from datetime import datetime, timezone
from app.core.enums import IssueStatus
from app.models.issue import Issue
from app.repositories.issue_repository import IssueRepository

class IssueService:
    @staticmethod
    async def create(db, reported_by_id, data):
        issue = Issue(
            service_request_id=data.service_request_id,
            assignment_id=data.assignment_id,
            reported_by_id=reported_by_id,
            title=data.title,
            description=data.description,
        )
        return await IssueRepository.create(db, issue)

    @staticmethod
    async def get(db, issue_id):
        issue = await IssueRepository.get_by_id(db, issue_id)
        if not issue:
            raise ValueError("Issue not found")
        return issue

    @staticmethod
    async def mine(db, user_id):
        return await IssueRepository.get_user_issues(db, user_id)

    @staticmethod
    async def all(db):
        return await IssueRepository.get_all(db)

    @staticmethod
    async def resolve(db, issue, resolution):
        issue.status = IssueStatus.RESOLVED
        issue.resolution = resolution
        issue.resolved_at = datetime.now(timezone.utc)
        return await IssueRepository.update(db, issue)

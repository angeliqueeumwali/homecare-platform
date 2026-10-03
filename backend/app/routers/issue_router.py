from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.schemas.issue_schema import IssueCreate, IssueResponse, IssueResolveRequest
from app.services.issue_service import IssueService

router = APIRouter(prefix="/issues", tags=["Issues"])

@router.post("", response_model=IssueResponse, status_code=201)
async def create_issue(data: IssueCreate, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    try:
        return await IssueService.create(db, current_user.id, data)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/me", response_model=list[IssueResponse])
async def my_issues(db=Depends(get_db), current_user: User=Depends(get_current_user)):
    return await IssueService.mine(db, current_user.id)

@router.get("", response_model=list[IssueResponse])
async def all_issues(db=Depends(get_db), _: object=Depends(require_roles(UserRole.ADMIN))):
    return await IssueService.all(db)

@router.patch("/{issue_id}/resolve", response_model=IssueResponse)
async def resolve_issue(issue_id, data: IssueResolveRequest, db=Depends(get_db), _: object=Depends(require_roles(UserRole.ADMIN))):
    try:
        issue = await IssueService.get(db, issue_id)
        return await IssueService.resolve(db, issue, data.resolution)
    except ValueError as e:
        raise HTTPException(404, str(e))

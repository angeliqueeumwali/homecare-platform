from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.routers.admin_router import router as admin_router
from app.routers.assignment_router import router as assignment_router
from app.routers.auth_router import router as auth_router
from app.routers.health_router import router as health_router
from app.routers.issue_router import router as issue_router
from app.routers.notification_router import router as notification_router
from app.routers.payment_router import router as payment_router
from app.routers.provider_router import router as provider_router
from app.routers.quote_router import router as quote_router
from app.routers.review_router import router as review_router
from app.routers.service_category_router import router as service_category_router
from app.routers.service_request_router import router as service_request_router
from app.routers.user_router import router as user_router


app = FastAPI(
    title="Homecare Platform API",
    version="1.0.0",
    description="Backend API for the Homecare Platform",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
os.makedirs(STATIC_DIR, exist_ok=True)
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


app.include_router(health_router)
app.include_router(admin_router)
app.include_router(auth_router)
app.include_router(user_router)
app.include_router(provider_router)
app.include_router(service_category_router)
app.include_router(service_request_router)
app.include_router(assignment_router)
app.include_router(quote_router)
app.include_router(payment_router)
app.include_router(notification_router)
app.include_router(review_router)
app.include_router(issue_router)


@app.get("/")
async def root():
    return {
        "message": "Homecare Platform API is running"
    }
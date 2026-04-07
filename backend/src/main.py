"""
Smart Student Task Prioritizer — FastAPI Backend
"""

from __future__ import annotations

import logging
import math
import os
from datetime import datetime, timezone
from functools import lru_cache
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Any, Dict, List, Optional
from uuid import uuid4

import joblib
import uvicorn
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from supabase import Client, create_client

# ─── Configuration ───────────────────────────────────────────────────────────

BACKEND_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND_DIR / ".env")

LOCAL_CORS_REGEX = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"


def _as_bool(value: str | None, default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _as_list(value: str | None) -> tuple[str, ...]:
    if not value:
        return ()
    return tuple(item.strip() for item in value.split(",") if item.strip())


def _resolve_path(value: str, base_dir: Path) -> Path:
    candidate = Path(value)
    if candidate.is_absolute():
        return candidate
    resolved = (base_dir / candidate).resolve()
    if resolved.exists():
        return resolved

    # Support both the current models/ layout and the legacy root-level files.
    fallback_paths = (
        (base_dir / "models" / candidate.name).resolve(),
        (base_dir / candidate.name).resolve(),
    )
    for fallback in fallback_paths:
        if fallback.exists():
            return fallback

    return resolved


@lru_cache(maxsize=1)
def get_settings():
    environment = os.getenv("APP_ENV", "development").strip().lower()
    cors_origins = _as_list(os.getenv("CORS_ORIGINS"))
    cors_origin_regex = os.getenv("CORS_ORIGIN_REGEX")

    if not cors_origins and not cors_origin_regex and environment != "production":
        cors_origin_regex = LOCAL_CORS_REGEX

    reload = _as_bool(os.getenv("RELOAD"), environment != "production")
    workers = int(os.getenv("UVICORN_WORKERS", "1"))

    class Settings:
        def __init__(self):
            self.app_name = "Smart Student Task Prioritizer"
            self.app_version = "1.0.0"
            self.environment = environment
            self.host = os.getenv("HOST", "0.0.0.0")
            self.port = int(os.getenv("PORT", "8000"))
            self.reload = reload
            self.workers = max(workers, 1)
            self.log_level = os.getenv("LOG_LEVEL", "INFO").upper()
            self.docs_enabled = _as_bool(os.getenv("ENABLE_DOCS"), environment != "production")
            self.force_https = _as_bool(os.getenv("FORCE_HTTPS"), environment == "production")
            self.trusted_hosts = _as_list(os.getenv("TRUSTED_HOSTS"))
            self.forwarded_allow_ips = os.getenv("FORWARDED_ALLOW_IPS", "*")
            self.cors_origins = cors_origins
            self.cors_origin_regex = cors_origin_regex
            self.supabase_url = os.getenv("SUPABASE_URL", "").strip()
            self.supabase_service_key = os.getenv("SUPABASE_SERVICE_KEY", "").strip()
            self.model_path = _resolve_path(os.getenv("MODEL_PATH", "models/priority_model.joblib"), BACKEND_DIR)
            self.encoder_path = _resolve_path(os.getenv("ENCODER_PATH", "models/category_encoder.joblib"), BACKEND_DIR)

        @property
        def is_production(self):
            return self.environment == "production"

        @property
        def cors_allow_credentials(self):
            return "*" not in self.cors_origins

        @property
        def missing_production_config(self):
            missing: list[str] = []
            if not self.supabase_url:
                missing.append("SUPABASE_URL")
            if not self.supabase_service_key:
                missing.append("SUPABASE_SERVICE_KEY")
            if not self.cors_origins and not self.cors_origin_regex:
                missing.append("CORS_ORIGINS")
            return tuple(missing)

    return Settings()


# ─── Logging ─────────────────────────────────────────────────────────────────

LOG_DIR = BACKEND_DIR / "logs"
LOG_FORMAT = "%(asctime)s | %(levelname)s | %(name)s | %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S"


def _normalize_level(level: str) -> str:
    value = level.strip().upper()
    return value if value in {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"} else "INFO"


def configure_application_logger(name: str = "smart_student", level: str = "INFO") -> logging.Logger:
    logger = logging.getLogger(name)
    if logger.handlers:
        logger.setLevel(_normalize_level(level))
        return logger

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)

    file_handler = RotatingFileHandler(
        LOG_DIR / "app.log", maxBytes=1_000_000, backupCount=5, encoding="utf-8",
    )
    file_handler.setFormatter(formatter)

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)

    logger.setLevel(_normalize_level(level))
    logger.addHandler(file_handler)
    logger.addHandler(stream_handler)
    logger.propagate = False
    return logger

settings = get_settings()
logger = configure_application_logger(level=settings.log_level)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    docs_url="/docs" if settings.docs_enabled else None,
    redoc_url="/redoc" if settings.docs_enabled else None,
)

if settings.trusted_hosts:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=list(settings.trusted_hosts))

if settings.force_https:
    app.add_middleware(HTTPSRedirectMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins),
    allow_origin_regex=settings.cors_origin_regex,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID"],
)


def _load_ml_engine() -> tuple[Any | None, Any | None, str]:
    try:
        rf_model = joblib.load(settings.model_path)
        category_encoder = joblib.load(settings.encoder_path)
        logger.info("ML engine active")
        return rf_model, category_encoder, "ml"
    except Exception as exc:
        logger.warning("ML engine fallback mode enabled: %s", exc)
        return None, None, "fallback"


def _build_supabase_client() -> Client | None:
    if not settings.supabase_url or not settings.supabase_service_key:
        logger.warning("Supabase configuration missing; database-backed routes will return 503")
        return None

    try:
        client: Client = create_client(settings.supabase_url, settings.supabase_service_key)
        logger.info("Supabase client initialized")
        return client
    except Exception as exc:
        logger.exception("Supabase client initialization failed: %s", exc)
        return None


rf_model, category_encoder, ml_mode = _load_ml_engine()
supabase: Client | None = _build_supabase_client()
security = HTTPBearer(auto_error=False)


class HealthResponse(BaseModel):
    status: str
    environment: str
    version: str
    ml_mode: str
    dependencies: Dict[str, bool]
    timestamp: str


class LoginRequest(BaseModel):
    email: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    user_id: str
    email: str


from enum import Enum

class TaskCategory(str, Enum):
    ACADEMIC = "Academic"
    PERSONAL = "Personal"
    EXTRACURRICULAR = "Extracurricular"

class TaskStatus(str, Enum):
    PENDING = "Pending"
    IN_PROGRESS = "In Progress"
    COMPLETED = "Completed"

class TaskCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    deadline: datetime
    task_weight: float = Field(..., ge=0.01, le=1.0)
    effort_level: int = Field(..., ge=1, le=5)
    category: TaskCategory
    description: Optional[str] = Field(default="", max_length=2000)


class TaskOut(BaseModel):
    id: str
    name: str
    deadline: str
    task_weight: float
    effort_level: int
    category: str
    description: Optional[str] = ""
    priority_score: float
    hours_remaining: float
    status: str
    nudge_message: str
    created_at: Optional[str] = None


class DashboardResponse(BaseModel):
    tasks: List[TaskOut]
    top_task: Optional[TaskOut]
    weekly_load: Dict[str, float]
    completion_rate: float


def _require_supabase() -> Client:
    if supabase is None:
        raise HTTPException(status_code=503, detail="Database dependency is not configured")
    return supabase


def _health_payload(status_label: str) -> HealthResponse:
    return HealthResponse(
        status=status_label,
        environment=settings.environment,
        version=settings.app_version,
        ml_mode=ml_mode,
        dependencies={
            "database_configured": supabase is not None,
            "ml_model_loaded": rf_model is not None and category_encoder is not None,
        },
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


def get_current_user(credentials: HTTPAuthorizationCredentials | None = Depends(security)):
    if credentials is None or not credentials.credentials:
        raise HTTPException(status_code=401, detail="Authentication required")

    client = _require_supabase()

    try:
        user_res = client.auth.get_user(credentials.credentials)
        if not user_res or not user_res.user:
            raise HTTPException(status_code=401, detail="Session expired")
        return user_res.user
    except HTTPException:
        raise
    except Exception:
        logger.warning("Authentication failed during token validation")
        raise HTTPException(status_code=401, detail="Authentication failed")


def predict_priority(hours: float, weight: float, effort: int, cat: str) -> float:
    if rf_model and category_encoder:
        try:
            cat_idx = int(category_encoder.transform([cat])[0])
            urgency = weight / math.log(max(hours, 0.1) + 1.5)
            feats = [hours, weight, effort, urgency, 1 - min(hours / 336, 1), effort / 5, 0.5, cat_idx]
            score = float(rf_model.predict([feats])[0])
            return round(max(0.0, min(score, 1.0)), 4)
        except Exception as exc:
            logger.warning("ML inference failed; using fallback scoring: %s", exc)

    urgency_score = (weight * 4) / math.log(max(hours, 0.5) + 2.0)
    effort_penalty = effort / 20
    return round(max(0.0, min(urgency_score + effort_penalty, 1.0)), 4)


def generate_nudge(score: float, name: str, hours: float) -> str:
    if score >= 0.75:
        return f"ASAP: '{name}' is critical ({int(hours)}h left)."
    if score >= 0.45:
        return f"Focus: '{name}' is high priority."
    return f"'{name}' is on track."


def parse_iso_datetime(dt_str: str) -> datetime:
    return datetime.fromisoformat(dt_str.replace("Z", "+00:00"))


def enrich_tasks(raw_tasks: list[dict[str, Any]], now: datetime) -> list[dict[str, Any]]:
    enriched: list[dict[str, Any]] = []
    for task in raw_tasks:
        task_copy = dict(task)
        deadline = parse_iso_datetime(task_copy["deadline"])
        hours = max((deadline - now).total_seconds() / 3600, 0.1)

        if task_copy["status"] != "Completed":
            task_copy["priority_score"] = predict_priority(
                hours,
                task_copy["task_weight"],
                task_copy["effort_level"],
                task_copy["category"],
            )
            task_copy["nudge_message"] = generate_nudge(task_copy["priority_score"], task_copy["name"], hours)
        else:
            task_copy["priority_score"] = 0.0

        task_copy["hours_remaining"] = round(hours, 2)
        enriched.append(task_copy)

    enriched.sort(key=lambda item: (item["status"] == "Completed", -item["priority_score"]))
    return enriched


@app.on_event("startup")
def on_startup():
    missing = settings.missing_production_config
    if settings.is_production and missing:
        logger.critical("Missing required production configuration: %s", ", ".join(missing))
        raise RuntimeError(f"Missing required production configuration: {', '.join(missing)}")

    logger.info(
        "FastAPI backend started env=%s docs=%s workers=%s ml_mode=%s",
        settings.environment,
        settings.docs_enabled,
        settings.workers,
        ml_mode,
    )


@app.on_event("shutdown")
def on_shutdown():
    logger.info("FastAPI backend stopped")


@app.middleware("http")
async def add_request_context(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID") or str(uuid4())
    request.state.request_id = request_id
    started = datetime.now(timezone.utc)

    try:
        response = await call_next(request)
    except Exception:
        logger.exception("Unhandled error request_id=%s path=%s", request_id, request.url.path)
        raise

    duration_ms = int((datetime.now(timezone.utc) - started).total_seconds() * 1000)
    response.headers["X-Request-ID"] = request_id
    logger.info(
        "%s %s -> %s (%sms) request_id=%s",
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
        request_id,
    )
    return response


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    request_id = getattr(request.state, "request_id", "unknown")
    logger.warning("Validation error request_id=%s path=%s errors=%s", request_id, request.url.path, exc.errors())
    return JSONResponse(
        status_code=422,
        content={
            "detail": "Invalid request payload",
            "errors": exc.errors(),
            "request_id": request_id,
        },
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", "unknown")
    logger.exception("Unhandled exception request_id=%s path=%s", request_id, request.url.path)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "request_id": request_id,
        },
    )


@app.get("/", response_model=HealthResponse)
def health_check():
    return _health_payload("online")


@app.get("/health/live", response_model=HealthResponse)
def live_check():
    return _health_payload("live")


@app.get("/health/ready")
def ready_check():
    payload = _health_payload("ready" if supabase is not None else "unready")
    if supabase is None:
        return JSONResponse(status_code=503, content=payload.model_dump())
    return payload


@app.post("/login", response_model=LoginResponse)
def login(body: LoginRequest):
    client = _require_supabase()
    try:
        res = client.auth.sign_in_with_password({"email": body.email, "password": body.password})
        logger.info("Login succeeded for user_id=%s", res.user.id)
        return LoginResponse(
            access_token=res.session.access_token,
            user_id=str(res.user.id),
            email=res.user.email,
        )
    except Exception:
        logger.warning("Login failed")
        raise HTTPException(status_code=401, detail="Invalid credentials")


@app.post("/signup", response_model=LoginResponse)
def signup(body: LoginRequest):
    client = _require_supabase()
    try:
        res = client.auth.sign_up({"email": body.email, "password": body.password})
        if not res.session:
            logger.info("Signup created pending verification")
            raise HTTPException(
                status_code=400,
                detail="Registration successful. Check your email for the verification link.",
            )
        logger.info("Signup succeeded for user_id=%s", res.user.id)
        return LoginResponse(
            access_token=res.session.access_token,
            user_id=str(res.user.id),
            email=res.user.email,
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.warning("Signup failed: %s", exc)
        raise HTTPException(status_code=400, detail="Unable to complete signup")


@app.post("/add-task", response_model=TaskOut, status_code=201)
def add_task(body: TaskCreate, current_user=Depends(get_current_user)):
    client = _require_supabase()
    now = datetime.now(timezone.utc)
    deadline = body.deadline if body.deadline.tzinfo else body.deadline.replace(tzinfo=timezone.utc)
    hours = max((deadline - now).total_seconds() / 3600, 0.1)
    score = predict_priority(hours, body.task_weight, body.effort_level, body.category)

    row = {
        "user_id": str(current_user.id),
        "name": body.name.strip(),
        "deadline": deadline.isoformat(),
        "task_weight": body.task_weight,
        "effort_level": body.effort_level,
        "category": body.category.value,
        "description": (body.description or "").strip(),
        "priority_score": score,
        "hours_remaining": round(hours, 2),
        "status": TaskStatus.PENDING.value,
        "nudge_message": generate_nudge(score, body.name, hours),
    }

    try:
        res = client.table("tasks").insert(row).execute()
        if not res.data:
            raise RuntimeError("Database insertion failed")
        logger.info("Task created for user_id=%s task=%s", current_user.id, body.name)
        return res.data[0]
    except Exception:
        logger.exception("Task creation failed for user_id=%s", current_user.id)
        raise HTTPException(status_code=500, detail="Database error while creating task")


@app.get("/tasks", response_model=List[TaskOut])
def get_tasks(current_user=Depends(get_current_user)):
    client = _require_supabase()
    now = datetime.now(timezone.utc)

    try:
        res = client.table("tasks").select("*").eq("user_id", str(current_user.id)).execute()
        tasks = enrich_tasks(res.data or [], now)
        logger.info("Tasks loaded for user_id=%s tasks=%s", current_user.id, len(tasks))
        return tasks
    except Exception:
        logger.exception("Task listing failed for user_id=%s", current_user.id)
        raise HTTPException(status_code=500, detail="Database error while loading tasks")


@app.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(current_user=Depends(get_current_user)):
    client = _require_supabase()
    now = datetime.now(timezone.utc)

    try:
        res = client.table("tasks").select("*").eq("user_id", str(current_user.id)).execute()
    except Exception:
        logger.exception("Dashboard query failed for user_id=%s", current_user.id)
        raise HTTPException(status_code=500, detail="Database error while loading dashboard")

    tasks = enrich_tasks(res.data or [], now)
    weekly_load = {day: 0.0 for day in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]}

    for task in tasks:
        if task["status"] != "Pending":
            continue
        deadline = parse_iso_datetime(task["deadline"])
        days_until_due = (deadline - now).days
        if 0 <= days_until_due <= 7:
            weekly_load[["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][deadline.weekday()]] += task["priority_score"]

    total = len(tasks)
    completed = sum(1 for task in tasks if task["status"] == "Completed")
    top_task = next((task for task in tasks if task["status"] != "Completed"), None)
    logger.info("Dashboard loaded for user_id=%s tasks=%s", current_user.id, total)

    return {
        "tasks": tasks,
        "top_task": top_task,
        "weekly_load": weekly_load,
        "completion_rate": round(completed / total, 2) if total else 0.0,
    }


@app.patch("/tasks/{task_id}/complete")
def complete_task(task_id: str, current_user=Depends(get_current_user)):
    client = _require_supabase()
    try:
        client.table("tasks").update({
            "status": TaskStatus.COMPLETED.value,
            "priority_score": 0.0
        }).eq("id", task_id).eq(
            "user_id", str(current_user.id)
        ).execute()
        logger.info("Task completed for user_id=%s task_id=%s", current_user.id, task_id)
        return {"status": "success"}
    except Exception as exc:
        logger.exception("Task completion failed for user_id=%s task_id=%s: %s", current_user.id, task_id, exc)
        raise HTTPException(status_code=500, detail="Database error while completing task")


@app.delete("/tasks/{task_id}")
def delete_task(task_id: str, current_user=Depends(get_current_user)):
    client = _require_supabase()
    try:
        client.table("tasks").delete().eq("id", task_id).eq("user_id", str(current_user.id)).execute()
        logger.info("Task deleted for user_id=%s task_id=%s", current_user.id, task_id)
        return {"status": "deleted"}
    except Exception:
        logger.exception("Task deletion failed for user_id=%s task_id=%s", current_user.id, task_id)
        raise HTTPException(status_code=500, detail="Database error while deleting task")


if __name__ == "__main__":
    uvicorn_target = "main:app" if settings.reload or settings.workers > 1 else app
    uvicorn.run(
        uvicorn_target,
        host=settings.host,
        port=settings.port,
        reload=settings.reload,
        workers=1 if settings.reload else settings.workers,
        log_level=settings.log_level.lower(),
        forwarded_allow_ips=settings.forwarded_allow_ips,
    )

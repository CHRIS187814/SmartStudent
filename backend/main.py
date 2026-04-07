"""
Smart Student Task Prioritizer — FastAPI Backend
"""

from __future__ import annotations
import math
import os
from datetime import datetime, timezone
from typing import List, Optional, Dict

import joblib
import numpy as np
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from supabase import Client, create_client

load_dotenv()

app = FastAPI(title="Smart Student Task Prioritizer", version="1.0.0")

# ─── CORS SETUP ──────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── SUPABASE ────────────────────────────────────────────────────────────────
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ─── ML ENGINE ───────────────────────────────────────────────────────────────
try:
    rf_model = joblib.load(os.getenv("MODEL_PATH", "priority_model.joblib"))
    category_encoder = joblib.load(os.getenv("ENCODER_PATH", "category_encoder.joblib"))
    print("✅ ML Engine: Active")
except Exception as e:
    print(f"⚠️  ML Engine: Fallback Mode ({e})")
    rf_model = None
    category_encoder = None

# ─── AUTH ────────────────────────────────────────────────────────────────────
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        user_res = supabase.auth.get_user(credentials.credentials)
        if not user_res or not user_res.user:
            raise HTTPException(status_code=401, detail="Session expired")
        return user_res.user
    except Exception:
        raise HTTPException(status_code=401, detail="Authentication failed")

# ─── MODELS ──────────────────────────────────────────────────────────────────
class LoginRequest(BaseModel):
    email: str
    password: str

class LoginResponse(BaseModel):
    access_token: str
    user_id: str
    email: str

class TaskCreate(BaseModel):
    name: str = Field(..., min_length=1)
    deadline: datetime
    task_weight: float = Field(..., ge=0.05, le=0.50)
    effort_level: int = Field(..., ge=1, le=5)
    category: str = Field(..., pattern="^(Academic|Personal|Extracurricular)$")
    description: Optional[str] = "" # Default to empty string to avoid 422 errors

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

# ─── LOGIC ───────────────────────────────────────────────────────────────────
def predict_priority(hours: float, weight: float, effort: int, cat: str) -> float:
    """Predicts a priority score between 0.0 and 1.0"""
    if rf_model and category_encoder:
        try:
            cat_idx = int(category_encoder.transform([cat])[0])
            # Calculated urgency feature for ML model
            urgency = weight / math.log(max(hours, 0.1) + 1.5)
            feats = [hours, weight, effort, urgency, 1-min(hours/336, 1), effort/5, 0.5, cat_idx]
            score = float(rf_model.predict([feats])[0])
            return round(max(0.0, min(score, 1.0)), 4)
        except: pass
    
    # Fallback Priority Math (Logarithmic Urgency + Effort Penalty)
    # Higher weight + closer deadline = higher score
    urgency_score = (weight * 4) / (math.log(max(hours, 0.5) + 2.0))
    effort_penalty = (effort / 20) 
    return round(max(0.0, min(urgency_score + effort_penalty, 1.0)), 4)

def generate_nudge(score: float, name: str, hours: float) -> str:
    if score >= 0.75: return f"🚨 ASAP: '{name}' is critical ({int(hours)}h left)!"
    if score >= 0.45: return f"⚡ Focus: '{name}' is high priority."
    return f"✅ '{name}' is on track."

def parse_iso_datetime(dt_str: str) -> datetime:
    """Helper to parse Supabase dates safely"""
    clean_ts = dt_str.replace("Z", "+00:00")
    return datetime.fromisoformat(clean_ts)

# ─── ROUTES ──────────────────────────────────────────────────────────────────

@app.get("/")
def health_check():
    return {"status": "online", "engine": "ML" if rf_model else "Fallback"}

@app.post("/login", response_model=LoginResponse)
def login(body: LoginRequest):
    try:
        res = supabase.auth.sign_in_with_password({"email": body.email, "password": body.password})
        return LoginResponse(access_token=res.session.access_token, user_id=str(res.user.id), email=res.user.email)
    except:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/signup", response_model=LoginResponse)
def signup(body: LoginRequest):
    try:
        res = supabase.auth.sign_up({"email": body.email, "password": body.password})
        if not res.session:
            raise HTTPException(status_code=400, detail="Registration successful! Check email for verification link.")
        return LoginResponse(access_token=res.session.access_token, user_id=str(res.user.id), email=res.user.email)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/add-task", response_model=TaskOut, status_code=201)
def add_task(body: TaskCreate, current_user=Depends(get_current_user)):
    now = datetime.now(timezone.utc)
    dt = body.deadline if body.deadline.tzinfo else body.deadline.replace(tzinfo=timezone.utc)
    hours = max((dt - now).total_seconds() / 3600, 0.1)

    score = predict_priority(hours, body.task_weight, body.effort_level, body.category)
    
    row = {
        "user_id": str(current_user.id),
        "name": body.name,
        "deadline": dt.isoformat(),
        "task_weight": body.task_weight,
        "effort_level": body.effort_level,
        "category": body.category,
        "description": body.description or "",
        "priority_score": score,
        "hours_remaining": round(hours, 2),
        "status": "Pending",
        "nudge_message": generate_nudge(score, body.name, hours)
    }

    try:
        res = supabase.table("tasks").insert(row).execute()
        if not res.data:
            raise Exception("Database insertion failed")
        return res.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/dashboard", response_model=DashboardResponse)
def get_dashboard(current_user=Depends(get_current_user)):
    now = datetime.now(timezone.utc)
    res = supabase.table("tasks").select("*").eq("user_id", str(current_user.id)).execute()
    raw_tasks = res.data or []

    enriched = []
    for t in raw_tasks:
        dt = parse_iso_datetime(t["deadline"])
        hours = max((dt - now).total_seconds() / 3600, 0.1)
        
        # Update live priority and nudges for pending tasks
        if t["status"] != "Completed":
            t["priority_score"] = predict_priority(hours, t["task_weight"], t["effort_level"], t["category"])
            t["nudge_message"] = generate_nudge(t["priority_score"], t["name"], hours)
        else:
            t["priority_score"] = 0.0
        
        t["hours_remaining"] = round(hours, 2)
        enriched.append(t)

    # Sort: Pending (Highest Score) first, then Completed at the bottom
    enriched.sort(key=lambda x: (x["status"] == "Completed", -x["priority_score"]))

    # Weekly Heatmap
    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    weekly_load = {d: 0.0 for d in days}
    for t in enriched:
        if t["status"] == "Pending":
            dt = parse_iso_datetime(t["deadline"])
            # Only count tasks in the next 7 days for the load chart
            if 0 <= (dt - now).days <= 7:
                weekly_load[days[dt.weekday()]] += t["priority_score"]

    total = len(enriched)
    completed = sum(1 for t in enriched if t["status"] == "Completed")

    # The top_task is the most urgent non-completed task
    top_task = next((t for t in enriched if t["status"] != "Completed"), None)

    return {
        "tasks": enriched,
        "top_task": top_task,
        "weekly_load": weekly_load,
        "completion_rate": round(completed / total, 2) if total > 0 else 0.0
    }

@app.patch("/tasks/{task_id}/complete")
def complete_task(task_id: str, current_user=Depends(get_current_user)):
    supabase.table("tasks").update({
        "status": "Completed", 
        "priority_score": 0.0
    }).eq("id", task_id).eq("user_id", str(current_user.id)).execute()
    return {"status": "success"}

@app.delete("/tasks/{task_id}")
def delete_task(task_id: str, current_user=Depends(get_current_user)):
    supabase.table("tasks").delete().eq("id", task_id).eq("user_id", str(current_user.id)).execute()
    return {"status": "deleted"}
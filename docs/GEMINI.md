# SmartStudent — Smart Student Task Prioritizer

## Project Overview
**SmartStudent** is an AI-powered task management system designed to help students prioritize their workload intelligently. It features a machine learning engine that predicts task priority scores based on multiple factors like urgency, task weight, and effort level.

### Architecture
- **Backend**: built with **FastAPI**, providing a RESTful API for task CRUD, authentication (via Supabase), and ML inference.
- **Frontend**: A **Flutter** mobile application for a cross-platform user experience.
- **ML Engine**: A **Scikit-Learn Random Forest Regressor** trained on synthetic student task data.
- **Database**: **Supabase (PostgreSQL)** utilizing Row Level Security (RLS) for multi-tenant data isolation.

---

## Directory Structure
- `backend/`: FastAPI server, ML models, and configuration.
  - `main.py`: API endpoints and core logic.
  - `scripts/train_model.py`: ML training pipeline.
  - `schema.sql`: Database schema and RLS policies.
  - `requirements.txt`: Python dependencies.
- `frontend/SmartStudent/`: Flutter mobile application.
  - `lib/`: Dart source code (screens, services, models).
  - `pubspec.yaml`: Flutter dependencies.

---

## Building and Running

### 1. Backend Setup
1.  **Environment**: Ensure `backend/.env` is configured with Supabase credentials.
2.  **Dependencies**: `pip install -r requirements.txt`
3.  **Train ML Model**: `python3 scripts/train_model.py` (optional, fallback engine active by default)
4.  **Start Server**: `uvicorn main:app --reload`

### 2. Frontend Setup
1.  **Dependencies**: `flutter pub get`
2.  **Run App**: `flutter run`

---

## Development Conventions

- **ML Integration**: The backend uses a fallback mathematical formula if the ML models (`.joblib` files) are missing or fail to load.
- **Database Security**: All task operations must respect `user_id` filtering, enforced by Supabase RLS policies.
- **Task Priority**: Scores range from `0.0` (Low) to `1.0` (Critical). Priority is recalculated dynamically in the dashboard based on time remaining.

## Key Technologies
- **Python**: FastAPI, Scikit-Learn, Joblib, Pandas, Supabase-py.
- **Dart**: Flutter, Http, Shared Preferences.
- **Database**: PostgreSQL (via Supabase).

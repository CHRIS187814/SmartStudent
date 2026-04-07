# SmartStudent — ML-Powered Task Prioritizer

A smart student task prioritizer that uses machine learning to rank tasks by urgency, weight, and effort. Built with **Flutter**, **FastAPI**, **Scikit-Learn**, and **Supabase**.

---

## Features

- 🧠 **ML-Powered Priority Scores** — Random Forest model predicts task priority (0.0–1.0)
- 📊 **Smart Dashboard** — Weekly heatmap, completion rate, daily focus card
- 🔔 **Intelligent Nudges** — Contextual messages like *"🚨 ASAP: 'Final Exam' is critical (24h left)!"*
- 🔐 **Secure Auth** — JWT-based authentication via Supabase
- 📱 **Cross-Platform** — Runs on iOS, Android, and Web

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | FastAPI + Uvicorn (Python) |
| ML Engine | Scikit-Learn, NumPy, Pandas |
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth + JWT |

---

## Project Structure

```
SmartStudent/
├── backend/
│   ├── main.py                 # FastAPI server with REST routes
│   ├── schema.sql              # Supabase SQL setup (tables, RLS, triggers)
│   ├── requirements.txt        # Python dependencies
│   ├── priority_model.joblib   # Trained Random Forest model
│   ├── category_encoder.joblib # LabelEncoder for categories
│   └── .env                    # Supabase credentials
├── frontend/
│   └── SmartStudent/
│       ├── lib/
│       │   ├── main.dart       # App entry point
│       │   ├── screens/        # Dashboard, TaskMaster, Analytics, Login
│       │   └── services/       # API & Auth services
│       └── pubspec.yaml
├── train_model.py              # ML training script
└── ppt.js                      # Presentation generator
```

---

## Quick Start

### Prerequisites

- **Python 3.11+** (for backend & ML training)
- **Flutter SDK 3.0+** (for frontend)
- **Supabase account** (free tier works)
- **Node.js** (optional, for presentation generation)

### 1. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Run the SQL setup: go to **SQL Editor** → paste contents of `backend/schema.sql` → **Run**
3. Get your credentials from **Project Settings → API**:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_KEY`

### 2. Train the ML Model

```bash
cd SmartStudent
pip install scikit-learn pandas numpy joblib
python train_model.py
```

**Output:** `priority_model.joblib` and `category_encoder.joblib`

### 3. Start the Backend

```bash
cd backend

# Create virtual environment (first time only)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
echo "SUPABASE_URL=your_url_here" > .env
echo "SUPABASE_SERVICE_KEY=your_key_here" >> .env

# Start the server
uvicorn main:app --reload --port 8000
```

API docs available at `http://localhost:8000/docs`

### 4. Run the Flutter App

```bash
cd frontend/SmartStudent
flutter pub get
flutter run
```

---

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/` | No | Health check |
| `POST` | `/login` | No | Authenticate user |
| `POST` | `/signup` | No | Register new user |
| `POST` | `/add-task` | Yes | Create task with ML priority score |
| `GET` | `/dashboard` | Yes | Get tasks + analytics |
| `PATCH` | `/tasks/{id}/complete` | Yes | Mark task completed |
| `DELETE` | `/tasks/{id}` | Yes | Delete a task |

---

## ML Model Details

- **Algorithm:** Random Forest Regressor (200 trees, max_depth=12)
- **Training Data:** 2,000 synthetic samples
- **Features:** hours_remaining, task_weight, effort_level, urgency_factor, category
- **Performance:** R² ≈ 0.97, RMSE ≈ 0.03
- **Categories:** Academic, Personal, Extracurricular

### Priority Formula (Fallback)

```
urgency_score = (weight × 4) / log(hours + 2.0)
effort_penalty = effort / 20
priority = urgency_score + effort_penalty
```

---

## Generate Presentation

```bash
npm install pptxgenjs
node ppt.js
```

Generates a 10-slide PowerPoint covering architecture, tech stack, and ML pipeline.

---

## Development

### Re-training the Model

Modify `train_model.py` with new data or parameters, then run:

```bash
python train_model.py
```

Copy the generated `.joblib` files to `backend/` if needed.

### Adding New Task Categories

Update the `category` CHECK constraint in `schema.sql` and the `LabelEncoder` categories in `train_model.py`.

---

## License

MIT — feel free to use for learning or projects.

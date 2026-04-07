# SmartStudent: Setup Instructions

## Prerequisites
- **Python 3.11+**
- **Flutter SDK**
- **Supabase Account** (for database and auth)

## Backend Setup
1. **Repository**: Clone and enter the `backend/` directory.
2. **Environment**: Create a `.env` file with your Supabase credentials:
   ```env
   SUPABASE_URL=...
   SUPABASE_SERVICE_KEY=...
   ```
3. **Environment**: Use a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
4. **Run**: `uvicorn src.main:app --reload`

## Frontend Setup
1. **Repository**: Enter the `frontend/SmartStudent/` directory.
2. **Dependencies**: `flutter pub get`
3. **Run**: `flutter run` (Ensure a simulator or device is connected).

## Common Issues
- **Supabase Connectivity**: Ensure RLS policies in `schema.sql` are applied to your Supabase project.
- **ML Model missing**: If `.joblib` files are not found, the system will use the mathematical fallback engine.

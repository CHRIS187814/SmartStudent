# SmartStudent: Repository Guidelines

## Project Structure & Module Organization
`backend/` contains the FastAPI source code in `src/main.py`, database setup in `src/database/schema.sql`, model artifacts (`priority_model.joblib`, `category_encoder.joblib`) in `models/`, helper scripts in `scripts/`, and local runtime output in `logs/`. `frontend/SmartStudent/` contains the Flutter client: `lib/main.dart` is the entrypoint, `lib/screens/` holds UI screens and tabs, and `lib/services/` wraps auth and API calls.

## Build, Test, and Development Commands
From `backend/`:

- `python3 -m pip install -r requirements.txt` installs API and ML dependencies.
- `uvicorn src.main:app --reload` starts the API at `http://localhost:8000`.
- `python3 scripts/train_model.py` retrains the model; run it from `backend/`.

From `frontend/SmartStudent/`:

- `flutter pub get` installs Dart packages.
- `flutter run` launches the app on the selected device or emulator.
- `flutter analyze` runs static analysis using `flutter_lints`.
- `flutter test` runs Dart tests when `test/` files are present.

## Coding Style & Naming Conventions
Use 4-space indentation in Python and standard Flutter formatting in Dart. Follow the existing naming style: `snake_case` for Python functions and files, `PascalCase` for Dart widgets and classes, and `camelCase` for Dart fields and methods. Keep backend route logic in `backend/src/main.py`, network access in `lib/services/`, and screen-specific UI in `lib/screens/`.

## Testing Guidelines
The Flutter app already includes `flutter_test`; place tests under `frontend/SmartStudent/test/` with names ending in `_test.dart`. The backend does not yet have a committed test harness, so new API tests should introduce a `backend/tests/` package and document any added test dependencies in `backend/requirements.txt`. Focus coverage on auth flows, task CRUD, and dashboard prioritization logic.

## Commit & Pull Request Guidelines
The current history is minimal (`first commit`), so use short imperative commit subjects such as `add dashboard refresh handling`. Keep commits scoped to one concern. Pull requests should describe backend and frontend impact, list the commands you ran, note schema or environment changes, and include screenshots for UI updates.

## Configuration Notes
Set `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` in a local `backend/.env` before running the API. When testing on a device or emulator, update `frontend/SmartStudent/lib/services/api_service.dart` so `baseUrl` points to the reachable backend host.

# SmartStudent: API Guide

This document provides a summary of the available endpoints in the SmartStudent FastAPI backend.

## Base URL
The local API is accessible at `http://localhost:8000`.

## Authentication
Most endpoints require a **Bearer Token** obtained via login or signup.

- `POST /signup`: Register a new user with email and password.
- `POST /login`: Authenticate and receive an access token.

## Tasks
- `GET /tasks`: Retrieve all tasks for the authenticated user.
- `POST /add-task`: Create a new task.
- `PATCH /tasks/{id}/complete`: Mark a task as completed.
- `DELETE /tasks/{id}`: Permanently remove a task.

## Dashboard
- `GET /dashboard`: Get prioritized task data, weekly workload, and completion stats.

## System Health
- `GET /`: Root health check and configuration status.
- `GET /health/live`: Liveness probe.
- `GET /health/ready`: Readiness probe (checks database connectivity).

---
*For detailed schema definitions, visit the Swagger UI at `/docs` while the server is running.*

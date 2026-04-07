FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt ./

RUN groupadd -r appgroup && useradd -r -g appgroup appuser && \
    python -m pip install --upgrade pip && \
    pip install -r requirements.txt && \
    mkdir -p logs models && chown -R appuser:appgroup /app

USER appuser

COPY --chown=appuser:appgroup . .

EXPOSE 8000

CMD ["sh", "-c", "exec python src/main.py"]

FROM python:3.12-slim

WORKDIR /app

# Install system deps needed by asyncpg / cryptography
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Non-root user for security
RUN adduser --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# The event bus is process-local, so keep one worker until Redis fan-out is added.
CMD alembic upgrade head && uvicorn main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1 \
    --ws websockets-sansio \
    --proxy-headers \
    --forwarded-allow-ips="*" \
    --access-log

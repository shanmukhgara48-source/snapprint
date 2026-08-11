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

# Health check. $PORT is injected by Railway at runtime and defaults to 8000
# for local `docker run`, matching the CMD below.
ENV PORT=8000
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f "http://localhost:${PORT}/health" || exit 1

# The event bus is process-local, so keep one worker until Redis fan-out is added.
# Railway (and most PaaS hosts) inject $PORT at runtime; railway.toml's
# deploy.startCommand overrides this CMD in production, but this stays
# correct on its own for `docker run` / other hosts.
CMD alembic upgrade head && uvicorn main:app \
    --host 0.0.0.0 \
    --port ${PORT:-8000} \
    --workers 1 \
    --ws websockets-sansio \
    --proxy-headers \
    --forwarded-allow-ips="*" \
    --access-log

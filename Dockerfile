# Multi-stage build for security and size optimization
FROM python:3.11-slim-bookworm AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

# Install dependencies in builder stage
COPY app/requirements.txt .
RUN pip install --target=/build/deps -r requirements.txt


# Production stage
FROM python:3.11-slim-bookworm AS production

# Security: Create non-root user
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid 1000 --shell /bin/bash --create-home appuser

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/deps \
    PORT=5000

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /build/deps /app/deps

# Copy application code
COPY --chown=appuser:appgroup app/ .

# Security: Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/api/health')" || exit 1

# Run with gunicorn for production
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]


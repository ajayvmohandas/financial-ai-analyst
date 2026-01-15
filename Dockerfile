# Financial Agentic AI System - Production Docker Image (FastAPI)
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-fra \
    tesseract-ocr-deu \
    tesseract-ocr-spa \
    libtesseract-dev \
    libleptonica-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    zlib1g-dev \
    libwebp-dev \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set work directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/data/vector_db \
    && mkdir -p /app/data/processed \
    && mkdir -p /app/data/raw_documents \
    && mkdir -p /app/logs

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# FastAPI configuration
ENV HOST=0.0.0.0 \
    PORT=8000

# Start command
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

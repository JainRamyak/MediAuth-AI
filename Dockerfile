FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy root requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything
COPY . .

# Set working directory to backend for runtime
WORKDIR /app/backend

# Create data directory for ChromaDB if it doesn't exist
RUN mkdir -p knowledge_base/chroma_store

# Hugging Face Spaces use port 7860 by default
ENV PORT=7860
EXPOSE 7860

# CMD to run the FastAPI app
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "7860"]

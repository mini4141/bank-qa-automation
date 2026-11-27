# Build context is ./sut so the FAQ corpus can be copied in:  docker build -f inquiry-chat/Dockerfile sut
FROM python:3.12-slim
WORKDIR /srv
RUN pip install --no-cache-dir uv==0.10.3
COPY inquiry-chat/pyproject.toml inquiry-chat/uv.lock ./
RUN uv sync --frozen --no-dev
COPY inquiry-chat/app ./app
COPY docs-corpus ./docs-corpus
ENV PATH="/srv/.venv/bin:$PATH" PYTHONUNBUFFERED=1
RUN useradd --no-create-home app
USER app
EXPOSE 3003
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3003"]

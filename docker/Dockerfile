FROM python:3.12.10-slim AS base

RUN apt update && apt install --no-install-recommends -y git curl && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ADD pyproject.toml .
ADD requirements.txt .
ADD docs docs
RUN pip install --no-cache-dir . && rm pyproject.toml requirements.txt
ENV PYTHONPATH=/app

FROM base AS gitlab_webhook
ADD pr_agent pr_agent
CMD ["python", "pr_agent/servers/gitlab_webhook.py"]

FROM base AS test
ADD requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements-dev.txt && rm requirements-dev.txt
ADD pr_agent pr_agent
ADD tests tests

FROM base AS cli
ADD pr_agent pr_agent
ENTRYPOINT ["python", "pr_agent/cli.py"]

FROM python:3.12-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive

# --- Base OS deps ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git jq ripgrep bash-completion \
    build-essential pkg-config libpq-dev \
    vim nano less \
  && rm -rf /var/lib/apt/lists/*

# --- Node.js 22 LTS (para CLIs opencode/gemini/claude) ---
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get update && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# pnpm via corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# --- uv (Python tooling) ---
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
  && ln -s /root/.local/bin/uv /usr/local/bin/uv

# --- Install global npm packages as root (before switching to dev user) ---
RUN npm install -g opencode-ai @google/gemini-cli @anthropic-ai/claude-code

# --- Create non-root user ---
RUN useradd -m -s /bin/bash dev \
  && mkdir -p /workspace \
  && chown -R dev:dev /workspace

USER dev
WORKDIR /workspace

# --- Install Spec Kit: Specify CLI ---
RUN uv tool install specify-cli || echo "Specify CLI install skipped (repo may not be public yet)"

# --- Python dependencies for agent skills ---
RUN pip install --user --no-cache-dir \
    psycopg[binary] \
    redis \
    openai \
    anthropic \
    google-generativeai \
    langchain \
    langchain-anthropic \
    langchain-openai \
    langchain-google-genai \
    pgvector \
    sqlalchemy \
    pydantic \
    pydantic-settings \
    python-dotenv \
    requests \
    httpx \
    rich \
    typer \
    loguru

# Convenience
ENV PATH="/home/dev/.local/bin:${PATH}"

# Bash prompt customization
RUN echo 'export PS1="\[\033[01;32m\]sdd-dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/dev/.bashrc

# Welcome message
RUN echo 'echo "🚀 SDD Development Environment Ready!"' >> /home/dev/.bashrc
RUN echo 'echo "📚 Run: specify --version | opencode --version | claude --version"' >> /home/dev/.bashrc

FROM mcr.microsoft.com/devcontainers/cpp:1-ubuntu-24.04

# ── uv (Python package manager) ───────────────────────────────────────────────
# Copy the uv binary directly from the official image — no apt or curl needed.
# Pin to a specific version for reproducible builds; bump deliberately.
COPY --from=ghcr.io/astral-sh/uv:0.8.21 /uv /uvx /usr/local/bin/

# Let uv manage its own Python install and write to a stable cache location.
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_CACHE_DIR=/opt/uv/cache \
    UV_LINK_MODE=copy \
    UV_PYTHON_PREFERENCE=only-managed

# Pre-install Python 3.13 so the first `uv sync` in post-create is instant.
RUN uv python install 3.13

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ninja-build \
    && rm -rf /var/lib/apt/lists/*

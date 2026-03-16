FROM mcr.microsoft.com/devcontainers/cpp:1-ubuntu-24.04

# ── uv (Python package manager) ───────────────────────────────────────────────
COPY --from=ghcr.io/astral-sh/uv:0.8.21 /uv /uvx /usr/local/bin/

ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_CACHE_DIR=/opt/uv/cache \
    UV_LINK_MODE=copy \
    UV_PYTHON_PREFERENCE=only-managed

RUN uv python install 3.13

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ninja-build \
        dos2unix \
    && rm -rf /var/lib/apt/lists/*
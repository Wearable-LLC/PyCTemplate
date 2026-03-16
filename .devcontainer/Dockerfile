FROM mcr.microsoft.com/devcontainers/cpp:1-ubuntu-24.04

# ── uv (Python package manager) ───────────────────────────────────────────────
COPY --from=ghcr.io/astral-sh/uv:0.8.21 /uv /uvx /usr/local/bin/

# Python install dir is root-owned and shared — vscode only needs read access.
# Cache dir is intentionally NOT set here; it is set per-user in devcontainer.json
# via remoteEnv so the vscode user writes to a path it owns (~/.cache/uv).
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_LINK_MODE=copy \
    UV_PYTHON_PREFERENCE=only-managed

# Pre-install Python 3.13 as root into the shared install dir.
# vscode reads this at runtime — no write access needed.
RUN uv python install 3.13 \
    && chmod -R a+rX /opt/uv/python

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ninja-build \
        dos2unix \
    && rm -rf /var/lib/apt/lists/*
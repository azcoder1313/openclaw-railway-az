FROM node:24-bookworm

# Clear proxy build args so apt-get can reach Debian repos directly
ENV HTTP_PROXY="" HTTPS_PROXY="" http_proxy="" https_proxy="" NO_PROXY="" no_proxy=""

RUN unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy no_proxy NO_PROXY \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gosu \
    procps \
    python3 \
    build-essential \
    zip \
    tini \
  && rm -rf /var/lib/apt/lists/*

RUN unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy no_proxy NO_PROXY \
  && npm install -g openclaw@latest clawhub@latest

# Backward-compatibility shim for older OPENCLAW_ENTRY values.
RUN mkdir -p /openclaw \
  && ln -sfn /usr/local/lib/node_modules/openclaw/dist /openclaw/dist

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy no_proxy NO_PROXY \
  && npm install -g pnpm@10 && pnpm install --prod

COPY src ./src
COPY --chmod=755 entrypoint.sh ./entrypoint.sh

RUN useradd -m -s /bin/bash openclaw \
  && chown -R openclaw:openclaw /app \
  && mkdir -p /data && chown openclaw:openclaw /data \
  && mkdir -p /home/linuxbrew/.linuxbrew && chown -R openclaw:openclaw /home/linuxbrew

USER openclaw
RUN unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy no_proxy NO_PROXY \
  && NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

ENV PORT=8080
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/setup/healthz || exit 1

USER root
ENTRYPOINT ["./entrypoint.sh"]

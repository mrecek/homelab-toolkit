################################################################################
# homelab-toolkit — General-purpose infrastructure operations container
#
# For homelab CI runners, Coder workspaces, and IaC workflows.
# Includes: Ansible, Azure CLI, OpenTofu, mise, just, GitHub CLI, code-server
#
# Base: python:3.12-slim (Debian)
################################################################################

FROM python:3.12-slim AS base

LABEL org.opencontainers.image.title="homelab-toolkit"
LABEL org.opencontainers.image.description="Homelab operations toolkit for CI runners and dev workspaces"
LABEL org.opencontainers.image.authors="Mark Recek"
LABEL org.opencontainers.image.source="https://github.com/mrecek/homelab-toolkit"

# Versions — update these to bump tools
ARG OPENTOFU_VERSION=1.9.0
ARG JUST_VERSION=1.40.0

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    sshpass \
    git \
    curl \
    wget \
    unzip \
    jq \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    iputils-ping \
    dnsutils \
    net-tools \
    iproute2 \
    traceroute \
    rsync \
    vim-tiny \
    less \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Azure CLI ────────────────────────────────────────────────────────────────
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*

# ── GitHub CLI ───────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# ── OpenTofu ─────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://get.opentofu.org/install-opentofu.sh" | bash -s -- --install-method deb \
    && rm -rf /var/lib/apt/lists/*

# ── just (task runner) ───────────────────────────────────────────────────────
RUN curl -fsSL "https://just.systems/install.sh" | bash -s -- --to /usr/local/bin

# ── mise (tool version manager) ──────────────────────────────────────────────
RUN curl -fsSL https://mise.run | sh \
    && ln -sf /root/.local/bin/mise /usr/local/bin/mise

# ── Python packages (core ops — baked system-wide) ───────────────────────────
RUN pip install --no-cache-dir \
    PyYAML>=6.0.1 \
    ansible>=9.4.0 \
    azure-identity>=1.16.0 \
    azure-keyvault-secrets>=4.8.0 \
    azure-cli-core>=2.75.0 \
    azure-mgmt-keyvault>=12.0.0 \
    jmespath>=1.0.1 \
    netaddr>=0.8.0 \
    requests>=2.31.0 \
    docker>=6.1.0

# ── Ansible collections (baked) ──────────────────────────────────────────────
RUN ansible-galaxy collection install \
    ansible.posix \
    azure.azcollection

# ── code-server (VS Code in browser — for Coder workspaces) ──────────────────
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ── Non-root users (GH Actions runs as root, ignores these) ─────────────────
# ops: general-purpose non-root user
# coder: Coder workspace user (shares UID 1000 with ops via -o flag)
RUN groupadd -g 1000 ops \
    && useradd -m -u 1000 -g ops -s /bin/bash ops \
    && echo "ops ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ops \
    && chmod 0440 /etc/sudoers.d/ops \
    && useradd -o -m -u 1000 -g ops -d /home/coder -s /bin/bash coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder

# Ensure mise works for non-root users + suppress Azure CLI first-run banner
RUN mkdir -p /home/ops/.local/bin /home/coder/.local/bin \
    /root/.azure /home/ops/.azure /home/coder/.azure \
    && ln -sf /usr/local/bin/mise /home/ops/.local/bin/mise \
    && ln -sf /usr/local/bin/mise /home/coder/.local/bin/mise \
    && printf '[core]\ncollect_telemetry = no\nfirst_run = no\n' \
      | tee /root/.azure/config /home/ops/.azure/config /home/coder/.azure/config > /dev/null \
    && chown -R ops:ops /home/ops \
    && chown -R 1000:1000 /home/coder

CMD ["/bin/bash"]

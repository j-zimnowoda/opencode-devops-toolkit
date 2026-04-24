# Build stage: install dependencies
FROM node:25-slim AS builder

ARG USER_UID=1000
ARG USER_GID=1000
ARG TARGETARCH=arm64
# Parameterize tool versions for easier updates
ARG NVM_VERSION=v0.40.1
ARG KUBECTL_VERSION=1.34.2
# https://github.com/helm/helm/tags
ARG HELM_VERSION=3.19.2
# https://github.com/databus23/helm-diff/releases
ARG HELMFILE_VERSION=1.2.2
# https://github.com/cloudnative-pg/cloudnative-pg/releases
ARG CNPG_VERSION=1.27.1
ARG HELM_FILE_NAME=helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz
ARG KUBECONFORM_VERSION=0.7.0

# Install base dependencies and useful CLI tools for coding agents
RUN apt-get update && apt-get install -y \
    git \
    curl \
    bash \
    ca-certificates \
    sudo \
    zip \
    unzip \
    wget \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    ripgrep \
    fd-find \
    jq \
    tree \
    less \
    procps \
    tmux \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*


# kubectl
RUN curl -LO "https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/$TARGETARCH/kubectl" && \
  curl -LO "https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/$TARGETARCH/kubectl.sha256" && \
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/

# cnpg kubectl plugin
RUN CNPG_ARCH=$(if [ "${TARGETARCH}" = "amd64" ]; then echo "x86_64"; else echo "${TARGETARCH}"; fi) && \
  curl -LO "https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v${CNPG_VERSION}/kubectl-cnpg_${CNPG_VERSION}_linux_${CNPG_ARCH}.tar.gz" && \
  tar -zxvf kubectl-cnpg_${CNPG_VERSION}_linux_${CNPG_ARCH}.tar.gz && \
  chmod +x kubectl-cnpg && \
  rm kubectl-cnpg_${CNPG_VERSION}_linux_${CNPG_ARCH}.tar.gz && \
  mv kubectl-cnpg /usr/local/bin/

# helm
ADD https://get.helm.sh/${HELM_FILE_NAME} /tmp
RUN tar -zxvf /tmp/${HELM_FILE_NAME} -C /tmp && mv /tmp/linux-${TARGETARCH}/helm /usr/local/bin/ 

# helmfile
ADD https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz /tmp
RUN tar -zxvf /tmp/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz -C /tmp && mv /tmp/helmfile /usr/local/bin/

# kubeconform
ADD https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-${TARGETARCH}.tar.gz /tmp
RUN tar -zxvf /tmp/kubeconform-linux-${TARGETARCH}.tar.gz -C /tmp && mv /tmp/kubeconform /usr/local/bin/


# # Create a script file sourced by both interactive and non-interactive bash shells
# ENV BASH_ENV ~/.bash_env
# RUN touch "${BASH_ENV}"
# RUN echo '. "${BASH_ENV}"' >> ~/.bashrc

# # NVM
# RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
# RUN nvm --version
# # Download and install nvm
# RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | PROFILE="${BASH_ENV}" bash
# RUN echo node > .nvmrc
# RUN nvm install
# yq
COPY --from=mikefarah/yq:4 /usr/bin/yq /usr/local/bin/yq

# OPENCODE
RUN npm install -g opencode-ai@1.14.21

# MCPs
RUN npm install -g @upstash/context7-mcp@2.1.8
RUN npm install -g @modelcontextprotocol/server-sequential-thinking@2025.12.18

# TOOLS
RUN npm install -g typescript-language-server@5.1.3
RUN npm install -g typescript@6.0.3
RUN npm install -g bun@1.3.10
RUN npm install -g @ast-grep/cli@0.42.1

# OPENSPEC
RUN npm install -g @fission-ai/openspec@v1.3.1

# VERIFICATION
RUN opencode models --refresh
RUN bun --version

# Runtime stage: minimal image
FROM node:25-slim

ARG USER_UID=1000
ARG USER_GID=1000


COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin
# COPY --from=builder /usr/bin /usr/bin

RUN usermod -u $USER_UID -o node && \
    groupmod -g $USER_GID node || true

# Create necessary directories with proper permissions
RUN mkdir -p /home/app/.config/opencode && \
    mkdir -p /home/app/.config/openspec && \
    mkdir -p /home/app/.local/share/opencode && \
    mkdir -p /home/app/.cache/opencode && \
    mkdir -p /home/app/.cache/oh-my-opencode && \
    mkdir -p /home/app/.cache/openspec && \
    mkdir -p /home/app/.gradle && \
    mkdir -p /home/app/.npm && \
    mkdir -p /home/app/.nvm && \
    mkdir -p /home/app/.m2 && \
    chown -R $USER_UID:$USER_GID /home/app

# /home/app/.local/share/opencode => here bun installs the opencode plugins (https://opencode.ai/docs/plugins/)
    
USER node
WORKDIR /home/app

# Add nvm, node, sdkman, uv, bun, and ast-grep to PATH
# Node.js is available via the NVM default symlink created above
ENV NVM_DIR="/home/app/.nvm"
ENV BUN_INSTALL="/home/app/.bun"
ENV PATH="/usr/local/bin:$BUN_INSTALL/bin:$NVM_DIR/default:/home/app/.local/bin:$PATH"
ENV OPENSPEC_TELEMETRY=0
ENV OMO_SEND_ANONYMOUS_TELEMETRY=0
ENV HOME=/home/app/

ENV DISPLAY=:99.0

ENV XDG_CONFIG_HOME=/home/app/.config
ENV OPENCODE_CONFIG_DIR=/home/app/.config/opencode
ENV XDG_DATA_HOME=/home/app/.local/share


# RUN opencode mcp list

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh



ENTRYPOINT ["entrypoint.sh"]

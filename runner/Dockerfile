# Self-hosted runner do GitHub Actions.
# Build:  docker build -t gh-runner ./runner
# Run:    veja o comando no fim do arquivo.
FROM ubuntu:24.04

# Vazio = baixa a última versão do actions/runner no build.
ARG RUNNER_VERSION=""
ARG DEBIAN_FRONTEND=noninteractive

# perl: shasum | git/jq/curl: usados por actions e scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git jq perl tar unzip \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        docker-ce-cli docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists/*

# O runner não roda como root: usuário comum.
RUN useradd -m -s /bin/bash runner
WORKDIR /home/runner/actions-runner

# Baixa e extrai o runner (x64 ou arm64, conforme a arquitetura do build).
RUN set -eux; \
    case "$(dpkg --print-architecture)" in amd64) arch=x64 ;; arm64) arch=arm64 ;; *) exit 1 ;; esac; \
    version="${RUNNER_VERSION:-$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')}"; \
    curl -fsSL -o runner.tar.gz "https://github.com/actions/runner/releases/download/v${version}/actions-runner-linux-${arch}-${version}.tar.gz"; \
    tar xzf runner.tar.gz; \
    rm runner.tar.gz; \
    ./bin/installdependencies.sh; \
    rm -rf /var/lib/apt/lists/*; \
    chown -R runner:runner /home/runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Variáveis recebidas em runtime (não coloque o token aqui):
#   GITHUB_URL     (obrigatória no 1º start) ex: https://github.com/<user>/<repo>
#   RUNNER_TOKEN   (obrigatória no 1º start) token de registro, expira em ~1h
#   RUNNER_NAME    (opcional) padrão: hostname do container
#   RUNNER_LABELS  (opcional) ex: docker,linux
ENTRYPOINT ["/entrypoint.sh"]

# docker run -d --name gh-runner --restart unless-stopped \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   -e GITHUB_URL=https://github.com/<user>/<repo> \
#   -e RUNNER_TOKEN=<token> \
#   gh-runner

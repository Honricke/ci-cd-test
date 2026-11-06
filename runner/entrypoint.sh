#!/bin/bash
set -euo pipefail

cd /home/runner/actions-runner

# Dá ao usuário runner acesso ao socket do Docker do host.
if [ -S /var/run/docker.sock ]; then
    gid=$(stat -c %g /var/run/docker.sock)
    getent group "$gid" >/dev/null || groupadd -g "$gid" dockerhost
    usermod -aG "$(getent group "$gid" | cut -d: -f1)" runner
fi

# Registra só na primeira vez; em restarts o .runner já existe.
if [ ! -f .runner ]; then
    : "${GITHUB_URL:?defina GITHUB_URL}"
    : "${RUNNER_TOKEN:?defina RUNNER_TOKEN}"
    runuser -u runner -- ./config.sh --unattended --replace \
        --url "$GITHUB_URL" \
        --token "$RUNNER_TOKEN" \
        --name "${RUNNER_NAME:-$(hostname)}" \
        ${RUNNER_LABELS:+--labels "$RUNNER_LABELS"}
fi

# O token não deve vazar para o ambiente dos jobs.
unset RUNNER_TOKEN
exec runuser -u runner -- ./run.sh

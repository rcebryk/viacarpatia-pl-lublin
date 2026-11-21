# "Osobna VM" na AI review: system z serwerem SSH, Javą (agent Jenkinsa),
# gitem i Pythonem z SDK Claude. W firmie: osobna maszyna wirtualna z Copilotem.
FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server openjdk-25-jre-headless git python3 python3-venv ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd \
    && useradd -m -s /bin/bash jenkins

COPY ai-review-vm/requirements.txt /opt/ai-review/requirements.txt
RUN python3 -m venv /opt/ai-review/venv \
    && /opt/ai-review/venv/bin/pip install --no-cache-dir -r /opt/ai-review/requirements.txt
ENV PATH="/opt/ai-review/venv/bin:${PATH}"

COPY common/agent-entrypoint.sh /usr/local/bin/agent-entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/bin/sh", "/usr/local/bin/agent-entrypoint.sh"]

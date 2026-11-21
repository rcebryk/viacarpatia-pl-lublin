#!/bin/sh
# Wspólny start agentów Jenkinsa łączonych przez SSH (build-agent, ai-review-vm).
# Klucz publiczny Jenkinsa przychodzi z zamontowanego katalogu secrets/.
set -e
install -d -m 700 -o jenkins -g jenkins /home/jenkins/.ssh
install -m 600 -o jenkins -g jenkins /secrets/jenkins_agent_key.pub /home/jenkins/.ssh/authorized_keys
# klucze hosta: stałe między restartami (Jenkins weryfikuje je w trybie "non verifying" w demo)
ssh-keygen -A >/dev/null
exec /usr/sbin/sshd -D -e

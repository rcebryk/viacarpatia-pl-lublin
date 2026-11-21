# Agent buildu Jenkinsa: Qt 6, CMake, Ninja + Java do uruchomienia agenta.
# Jenkins łączy się z nim przez SSH (jak z osobnym serwerem buildów).
FROM registry.fedoraproject.org/fedora:45

RUN dnf -y install --setopt=install_weak_deps=False \
        gcc-c++ cmake ninja-build git file tar xz openssl \
        qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qttools-devel qt6-linguist \
        java-25-openjdk-headless openssh-server \
    && dnf clean all \
    && useradd -m -s /bin/bash jenkins

COPY common/agent-entrypoint.sh /usr/local/bin/agent-entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/bin/sh", "/usr/local/bin/agent-entrypoint.sh"]

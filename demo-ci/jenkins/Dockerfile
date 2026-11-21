# Jenkins z wtyczkami i konfiguracją jako kod (JCasC) - bez klikania w kreatorze
FROM jenkins/jenkins:2.580.2-lts-jdk25

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY jenkins/casc.yaml /usr/share/jenkins/ref/casc.yaml.override
COPY jenkins/init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

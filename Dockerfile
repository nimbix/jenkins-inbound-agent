ARG AGENT_VERSION=4.6-1
FROM docker.io/jenkins/inbound-agent:$AGENT_VERSION

USER root
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get -y install --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

ARG TARGETARCH

# Install docker cli and other needed packages
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
        echo "deb [arch=$TARGETARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends docker-ce-cli make jq expect unzip gnupg bash

# Set bash as the default shell
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Install kubectl
RUN cd /usr/bin && curl --fail -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/${TARGETPLATFORM:-linux/amd64}/kubectl" && chmod 0555 kubectl

# Install helm
RUN curl -H 'Cache-Control: no-cache' \
    https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 | \
    bash -s -- --version v3.2.4

# Install terraform
ENV TF_VER_DEFAULT "1.0.0"
ENV TF_VERS "$TF_VER_DEFAULT 0.14.11"
RUN for tf_ver in $TF_VERS; do curl --silent https://releases.hashicorp.com/terraform/$tf_ver/terraform_${tf_ver}_linux_${TARGETARCH}.zip >/tmp/tf.zip && unzip /tmp/tf.zip -d /usr/local/bin && mv /usr/local/bin/terraform /usr/local/bin/terraform-$tf_ver; done
RUN ln -s terraform-$TF_VER_DEFAULT /usr/local/bin/terraform

USER jenkins


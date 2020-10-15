# FROM containers.intersystems.com/intersystems/iris-community:2020.3.0.200.0
FROM intersystemsdc/iris-community:2020.3.0.221.0-zpm

# ready to be as a devcontainer
ARG DEVCONTAINER="false"
USER root
RUN [ "$DEVCONTAINER" != "true" ] && exit; \
  apt-get update && export DEBIAN_FRONTEND=noninteractive && \
  apt-get -y install \
    git \
    openssh-client \
    gnupg2 \
    curl \
    wget \
    jq \
    sudo \
  && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/* && \
  echo $ISC_PACKAGE_MGRUSER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$ISC_PACKAGE_MGRUSER && \
  chmod 0440 /etc/sudoers.d/$ISC_PACKAGE_MGRUSER
USER ${ISC_PACKAGE_MGRUSER}
RUN [ "$DEVCONTAINER" != "true" ] && exit; \
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash && \
  source $HOME/.nvm/nvm.sh && nvm install 12 && \
  npm i -g newman
# end devcontainer

COPY --chown=irisowner:irisowner . /home/irisowner/conduit/

WORKDIR /home/irisowner/conduit/

RUN \
    iris start $ISC_PACKAGE_INSTANCENAME && \
    iris session $ISC_PACKAGE_INSTANCENAME < iris.script && \
    iris stop $ISC_PACKAGE_INSTANCENAME quietly

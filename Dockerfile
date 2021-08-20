FROM intersystemsdc/iris-community:latest

SHELL ["/bin/bash", "-c"]

# ready to be as a devcontainer
ARG DEVCONTAINER="false"

RUN [ "$DEVCONTAINER" != "true" ] && exit || \
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash && \
  source $HOME/.nvm/nvm.sh && nvm install 12 && \
  npm i -g newman
# end devcontainer

COPY --chown=irisowner:irisowner . /home/irisowner/conduit/

WORKDIR /home/irisowner/conduit/

RUN \
    iris start $ISC_PACKAGE_INSTANCENAME && \
    iris session $ISC_PACKAGE_INSTANCENAME < iris.script && \
    iris stop $ISC_PACKAGE_INSTANCENAME quietly

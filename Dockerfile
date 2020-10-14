# FROM containers.intersystems.com/intersystems/iris-community:2020.3.0.200.0
FROM intersystemsdc/iris-community:2020.3.0.221.0-zpm

COPY --chown=irisowner:irisowner . /home/irisowner/conduit/

WORKDIR /home/irisowner/conduit/

RUN \
    iris start $ISC_PACKAGE_INSTANCENAME && \
    iris session $ISC_PACKAGE_INSTANCENAME < iris.script && \
    iris stop $ISC_PACKAGE_INSTANCENAME quietly

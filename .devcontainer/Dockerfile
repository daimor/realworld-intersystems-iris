FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:12

RUN npm i -g newman && \
    apt-get update && apt-get install gnupg2 -y

CMD [ "sleep", "infinity" ]

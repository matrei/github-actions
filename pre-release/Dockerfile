# Container image that runs your code
FROM alpine:3

RUN apk add --no-cache curl jq git bash

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY *.sh /

# Code file to execute when the docker container starts up (`entrypoint.sh`)
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

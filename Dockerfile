FROM photon:4.0
LABEL maintainer="Michael Stanclift <https://github.com/vmstan>"

RUN tdnf update -y \
    && tdnf install -y curl git rsync openssh

RUN curl -sSL http://gravity.vmstan.com/beta | GS_DOCKER=1 && GS_DEV=4.0.0 bash

CMD gravity-sync version
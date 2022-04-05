FROM alpine:latest
LABEL maintainer="Michael Stanclift <https://github.com/vmstan>"

RUN apk update
RUN apk upgrade
RUN set -ex \
    && apk add --update --no-cache coreutils curl git rsync ca-certificates jq tzdata \
    && update-ca-certificates \
    && echo $TZ > /etc/timezone \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && date \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

RUN curl -sSL http://gravity.vmstan.com/beta | GS_DOCKER=1 && GS_DEV=4.0.0 bash
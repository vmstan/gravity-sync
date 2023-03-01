<p align="center">
<img src="https://vmstan.com/content/images/2021/02/gs-logo.svg" width="300" alt="Gravity Sync">
</p>

<span align="center">

# Pihole with Gravity Sync - Docker

</span>

This docker image bundles the official [pihole](https://github.com/pi-hole/pi-hole) docker image with [gravity-sync](https://github.com/vmstan/gravity-sync) on top (pihole-gravity-sync). Ideally, you just replace your existing pihole docker containers with this pihole-gravity-sync container and sync it against your other gravity-sync enabled hosts or other pihole-gravity-sync containers.

## Features

All features of [pihole](https://github.com/pi-hole/pi-hole) and [gravity-sync](https://github.com/vmstan/gravity-sync) in one docker image!
You can set all config variables of [pihole](https://hub.docker.com/r/pihole/pihole) and gravity-sync [1](https://github.com/vmstan/gravity-sync/wiki/Hidden-Figures) [2](https://github.com/vmstan/gravity-sync/wiki/Installing#configuration) via ENVs!
Ontop of these ENVs, you can set the following ENVs for configuring settings, special to this very container

- LOCAL_USER: Default: gs. SSH user to access this container via gravity-sync
- LOCAL_PASSWORD: Default: <empty>. SSH password for LOCAL_USER. If empty, a random password will be generated everytime the container starts. Can be overwritten via docker ENVs
- PASSWORD_MIN_LEN: Default: 8. Minimal length for externally set static password via LOCAL_PASSWORD
- GS_AUTO_MODE: Default: sync. Synchroniztion mode of this container. Valid options are "sync", "smart" (which are the same), "pull" and "push".
- GS_AUTO_DELAY: Default: <empty>. If set, this is the default interval for running the sync in minutes.
- GS_AUTO_JITTER: Default: <empty>. If set, this is the default additional random delay/jitter on GS_AUTO_DELAY to randomize sync times. Ideally, keep this below GS_AUTO_DELAY/2.
- GS_AUTO_DEBUG: Default: <empty>. If set to true, the synchronization will run every minute with no jitter.

## Setup Steps

#TODO Show a working docker-compose yml

1. Configure your pihole instance(s) like described (here)[https://hub.docker.com/r/pihole/pihole]. docker-compose is highly suggested.
2. Link the containers... TODO: docker exec -it <remote container> cat password to get the (temporary) SSH password of that container.
3. Enable auto sync docker exec -it <local container> gravity-sync configure

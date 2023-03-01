<p align="center">
<img src="https://vmstan.com/content/images/2021/02/gs-logo.svg" width="300" alt="Gravity Sync">
</p>

<span align="center">

# sync-hole: Pi-hole with gravity-sync

</span>

This docker image bundles the official [pi-hole docker image](https://github.com/pi-hole/docker-pi-hole) with [gravity-sync](https://github.com/vmstan/gravity-sync) on top as `sync-hole`.
It is a drop-in replacement for pi-hole and ideally, you just replace your existing pi-hole container with the `sync-hole` container. From inside this container you can run gravity-sync against other `sync-hole` instances or the standard gravity-sync in either direction (push, pull, auto/sync).

## Features

All features of [pi-hole](https://github.com/pi-hole/docker-pi-hole) and [gravity-sync](https://github.com/vmstan/gravity-sync) in one unified docker image!
The configuration is mainly performed via the ENVs of [pi-hole](https://hub.docker.com/r/pihole/pihole) and the ones made available by [gravity-sync](https://github.com/vmstan/gravity-sync/wiki/Installing#configuration).

### Gravity-sync ENVs
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| LOCAL_PIHOLE_DIRECTORY | path | `/etc/pihole` | Path, where pihole is installed locally.
| REMOTE_PIHOLE_DIRECTORY | path | '/etc/pihole'}           # replace in gravity-sync.conf to overwrite
| LOCAL_DNSMASQ_DIRECTORY | path | '/etc/dnsmasq.d'}        # replace in gravity-sync.conf to overwrite
| REMOTE_DNSMASQ_DIRECTORY | path | '/etc/dnsmasq.d'}      # replace in gravity-sync.conf to overwrite
| LOCAL_FILE_OWNER | string | 'pihole:pihole'}                       # replace in gravity-sync.conf to overwrite
| REMOTE_FILE_OWNER | string | 'pihole:pihole'}                     # replace in gravity-sync.conf to overwrite

# Pi-hole Docker/Podman container name - Docker will pattern match anything set below
| LOCAL_DOCKER_CONTAINER | string | 'pihole'}                  # replace in gravity-sync.conf to overwrite
| REMOTE_DOCKER_CONTAINER | string | 'pihole'}                # replace in gravity-sync.conf to overwrite

# STANDARD VARIABLES #########################

| DEFAULT_PIHOLE_DIRECTORY | path | '/etc/pihole'
| LOCAL_PIHOLE_BINARY | path | '/usr/local/bin/pihole'
| REMOTE_PIHOLE_BINARY |  path| '/usr/local/bin/pihole'
| LOCAL_FTL_BINARY | path | '/usr/bin/pihole-FTL'
| REMOTE_FTL_BINARY | path | '/usr/bin/pihole-FTL'
| LOCAL_DOCKER_BINARY | path | '/usr/bin/docker'
| REMOTE_DOCKER_BINARY | path | '/usr/bin/docker'
| LOCAL_PODMAN_BINARY | path | '/usr/bin/podman'
| REMOTE_PODMAN_BINARY | path | '/usr/bin/podman'
| PIHOLE_CONTAINER_IMAGE | path | 'pihole/pihole'

###############################################
####### THE NEEDS OF THE MANY, OUTWEIGH #######
############ THE NEEDS OF THE FEW #############
###############################################

| PH_GRAVITY_FI | | 'gravity.db'
| PH_CUSTOM_DNS | | 'custom.list'
| PH_CNAME_CONF | | '05-pihole-custom-cname.conf'
| PH_SDHCP_CONF | | '04-pihole-static-dhcp.conf'

# Backup Customization
| GS_BACKUP_TIMEOUT | | '240'
| GS_BACKUP_INTEGRITY_WAIT | | '5'
| GS_BACKUP_EXT | | 'gsb'

# GS Folder/File Locations
| GS_ETC_PATH | | "/etc/gravity-sync"
| GS_CONFIG_FILE | | 'gravity-sync.conf'
| GS_SYNCING_LOG | | 'gs-sync.log'
| GS_GRAVITY_FI_MD5_LOG | | 'gs-gravity.md5'
| GS_CUSTOM_DNS_MD5_LOG | | 'gs-clist.md5'
| GS_CNAME_CONF_MD5_LOG | | '05-pihole-custom-cname.conf.md5'
| GS_SDHCP_CONF_MD5_LOG | | '04-pihole-static-dhcp.conf.md5'

# SSH Customization
| GS_SSH_PORT=${GS_SSH_PORT:-'22'}                                # replace in gravity-sync.conf to overwrite
| GS_SSH_PKIF=${GS_SSH_PKIF:-"${GS_ETC_PATH}/gravity-sync.rsa"}   # replace in gravity-sync.conf to overwrite

# Github Customization
| GS_LOCAL_REPO=${GS_LOCAL_REPO:-"${GS_ETC_PATH}/.gs"}            # replace in gravity-sync.conf to overwrite


| `TZ` | UTC | `<Timezone>` | Set your [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) to make sure logs rotate at local midnight instead of at UTC midnight.
| `WEBPASSWORD` | random | `<Admin password>` | http://pi.hole/admin password. Run `docker logs pihole \| grep random` to find your random pass.
| `FTLCONF_LOCAL_IPV4` | unset | `<Host's IP>` | Set to your server's LAN IP, used by web block modes.


/[gravity-sync enhanced](https://github.com/vmstan/gravity-sync/wiki/Hidden-Figures)
Ontop of the ENVs of pihole and gravity-sync, you can set the following ENVs for tweaking this container.

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

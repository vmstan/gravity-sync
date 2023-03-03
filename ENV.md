<p align="center">
<img src="https://vmstan.com/content/images/2021/02/gs-logo.svg" width="300" alt="Gravity Sync">
</p>

<span align="center">

# Gravity-sync ENVs

</span>

These tables are a list of all gravity-sync settings, that can be tweaked via ENVs. Keep in mind that some of them are stored in `/etc/gravity-sync/gravity-sync.conf` after running `gravity-sync configure` and that `gravity-sync.conf` has higher priority than ENVs.

### Local and remote paths & settings
These settings will determine, from where (locally) to where (remotely) will be synced and with which account/permissions
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `LOCAL_PIHOLE_DIRECTORY` | `/etc/pihole` | path | Path to local pi-hole instance in the filesystem
| `REMOTE_PIHOLE_DIRECTORY` | `/etc/pihole` | path | Path to remote pi-hole instanc in the filesystem
| `LOCAL_DNSMASQ_DIRECTORY` | `/etc/dnsmasq.d` | path | Path to local dnsmasqd instance in the filesystem
| `REMOTE_DNSMASQ_DIRECTORY`  | `/etc/dnsmasq.d` | path | Path to remote dnsmasqd instance in the filesystem
| `LOCAL_FILE_OWNER`  | `pihole:pihole` | user:group | Local owner and group of the pi-hole config
| `REMOTE_FILE_OWNER` | `pihole:pihole` | user:group | Remote owner and group of the pi-hole config

### Docker specific settings
Gravity-sync will check your system for a native pi-hole install first (on local and remote site) and if does not detect any, tests against docker/podman pi-hole instances.
Here, you can specific the docker or podman container name, that gravity-sync should interact with.
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `LOCAL_DOCKER_CONTAINER` | `pihole` | container name | Container name of pi-hole running locally
| `REMOTE_DOCKER_CONTAINER` | `pihole` | container name | Container name of pi-hole running remotely

### Paths to standard files and folders
These settings are most likely the same on all systems. No need to touch them but nice to be able to touch them, if necessary.
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `DEFAULT_PIHOLE_DIRECTORY` | `/etc/pihole` | path | Docker/Podman: Path to pi-hole instance within a docker/podman containrt. Don't mix up with `LOCAL_PIHOLE_DIRECTORY`, which is only used against local pi-hole instances (non-dockerized).
| `LOCAL_PIHOLE_BINARY`  | `/usr/local/bin/pihole` | path | Path to `pihole` binary on local system
| `REMOTE_PIHOLE_BINARY` | `/usr/local/bin/pihole` |  path | Path to `pihole` binary on remote system
| `LOCAL_FTL_BINARY` | `/usr/bin/pihole-FTL` | path | Path to `pihole-FTL` binary on local system
| `REMOTE_FTL_BINARY` | `/usr/bin/pihole-FTL` | path | Path to `pihole-FTL` binary on remote system
| `LOCAL_DOCKER_BINARY` | `/usr/bin/docker` | path | Path to `docker` binary on local system
| `REMOTE_DOCKER_BINARY` | `/usr/bin/docker` | path | Path to `docker` binary on remote system
| `LOCAL_PODMAN_BINARY` | `/usr/bin/podman` | path | Path to `podman` binary on local system
| `REMOTE_PODMAN_BINARY` | `/usr/bin/podman` | path | Path to `podman` binary on remote system
| `PIHOLE_CONTAINER_IMAGE` | `pihole/pihole` | path | Name of the default pi-hole docker image

### Nitty-gritty finetuning the target files
Here, you can specifiy the gravity, DNS (A, CNAME) and DHCP settings file of pi-hole. It is almost certain, that these filenames do never change (except upstream pi-hole decides so). Better do not touch them.
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `PH_GRAVITY_FI` | `gravity.db` | file | The gravity filename (blocklist) of pihole
| `PH_CUSTOM_DNS` | `custom.list`  | file | The custom DNS (A) filename of pihole
| `PH_CNAME_CONF` | `05-pihole-custom-cname.conf` | file | The custom DNS (CNAME) filename of pihole
| `PH_SDHCP_CONF` | `04-pihole-static-dhcp.conf` | file | The custom DHCP filename of pihole

### Backup Customization
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `GS_BACKUP_TIMEOUT` | `240` | seconds | How long shall we allow a gravity.db backup task to run, before it is deemed to be timed out?
| `GS_BACKUP_INTEGRITY_WAIT` | `5` | seconds | Some wait time, before integrity checks are performed on gravity.db
| `GS_BACKUP_EXT` | `gsb` | file-extension | Local and remote gravity.db backup files will get this file-extension added before merge.

### GS Folder/File Locations
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `GS_ETC_PATH` | `/etc/gravity-sync` | path | Path to the gravity-sync work & config directory
| `GS_CONFIG_FILE` | `gravity-sync.conf` | file | Name of the gravity.sync config file
| `GS_SYNCING_LOG` | `gs-sync.log` | file  | Logfile for gravity-sync
| `GS_GRAVITY_FI_MD5_LOG` | `gs-gravity.md5`  | file | Filename for storing `PH_GRAVITY_FI` hash (used for sync comparison locally and on remote)
| `GS_CUSTOM_DNS_MD5_LOG` | `gs-clist.md5`  | file | Filename for storing `PH_CUSTOM_DNS` hash (used for sync comparison locally and on remote)
| `GS_CNAME_CONF_MD5_LOG` | `05-pihole-custom-cname.conf.md5` | file | Filename for storing `PH_CNAME_CONF` hash (used for sync comparison locally and on remote)
| `GS_SDHCP_CONF_MD5_LOG` | `04-pihole-static-dhcp.conf.md5` | file | Filename for storing `PH_SDHCP_CONF` hash (used for sync comparison locally and on remote)

### Remote SSH config
Customize parameters for accessing the remote end via SSH
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `GS_SSH_PORT` |  `22` | port | Port of the remote gravity-sync container/host
| `GS_SSH_PKIF` | `<GS_ETC_PATH>/gravity-sync.rsa` | file | Path to the local SSH private key of gravity-sync, that will be used for pubkey auth against the remote

### Upgrade: Gravity-sync sourcecode location
Gravity-sync is locally installed as a github repo. In order to upgrade your local gravity-sync instance via `gravity-sync upgrade` to the latest version, the path to that git-repo must be known and can be specified below.
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `GS_LOCAL_REPO` | `<GS_ETC_PATH>/.gs"` | path | Local install path of the gravity-sync repo

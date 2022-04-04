There are a series of advanced configuration options that you may need to change to better adapt Gravity Sync to your environment. They are referenced at the end of the `gravity-sync.conf` file. It is suggested that you make any necessary variable changes to this file, as they will supersede the ones located in the core script. If you want to revert back to the Gravity Sync default for any of these settings, just apply a `#` to the beginning of the line to comment it out.

### `PH_IN_TYPE` and `RH_IN_TYPE`

These variables allow you to configure either a default/standard Pi-hole installation on both the local and remote hosts. Available options are either `default` or `docker` exactly has written.

- Default setting in Gravity Sync is `default`.
- These variables can be set via `./gravity-sync.sh config` function.

### `PIHOLE_DIR` and `RIHOLE_DIR`

These variables allow you to change the location of the Pi-hole settings folder on both the local and remote hosts. This is required for Docker installations of Pi-hole. This directory location should be from the root of the file system and be configured **without** a trailing slash.

- Default setting in Gravity Sync is `/etc/pihole`.
- These variables can be set via `./gravity-sync.sh config` function and required if a Docker install is selected.

### `DNSMAQ_DIR` and `RNSMAQ_DIR`

These variables allow you to change the location of the DNSMASQ settings folder on both the local and remote hosts. This is required for Docker installations of Pi-hole. This directory location should be from the root of the file system and be configured **without** a trailing slash.

- Default setting in Gravity Sync is `/etc/dnsmaq.d`.
- These variables can be set via `./gravity-sync.sh config` function and required if a Docker install is selected.

### `PIHOLE_BIN` and `RIHOLE_BIN`

These variables allow you to change the location of the Pi-hole binary folder on both the local and remote hosts. Unless you've done a custom Pi-hole installation, this setting is unlikely to require changes. This directory location should be from the root of the file system and be configured **without** a trailing slash.

- Default setting in Gravity Sync is `/usr/local/bin/pihole`.

### `DOCKER_BIN` and `ROCKER_BIN`

These variables allow you to change the location of the Docker binary folder on both the local and remote hosts. This may be necessary on some systems, if you've done a custom installation of Docker. This directory location should be from the root of the file system and be configured **without** a trailing slash.

- Default setting in Gravity Sync is `/usr/bin/docker`.

### `FILE_OWNER` and `RILE_OWNER`

These variables allow you to change the file owner of the Pi-hole gravity database on both the local and remote hosts. This is required for Docker installations of Pi-hole, but is likely unnecessary on standard installs.

- Default setting in Gravity Sync is `pihole:pihole`.
- These variables are set via `./gravity-sync.sh config` function to `named:docker` automatically if a Docker install is selected.

### `DOCKER_CON` and `ROCKER_CON`

These variables allow you to change the location of the name of the Docker container on both the local and remote hosts.

- Default setting in Gravity Sync is `pihole`.
- These variables can be set via `./gravity-sync.sh config` function.

### `GRAVITY_FI`

This variable is for the `gravity.db` file that is replicated by Gravity Sync. You should not this them unless Pi-hole changes the naming convention for the database, in which case the core Gravity Sync files will be changed to adapt.

### `CUSTOM_DNS` and `CNAME_CONF`

These variables are for the `custom.list` and `05-pihole-custom-cname.conf` files that contain the Local DNS functions in Pi-hole, which are replicated by Gravity Sync. You should not change them unless Pi-hole changes their naming convention for these files, in which case the core Gravity Sync files will be changed to adapt.

### `VERIFY_PASS`

Gravity Sync will prompt to verify user interactivity during push, restore, or config operations (that overwrite an existing configuration) with the intention that it prevents someone from accidentally automating in the wrong direction or overwriting data intentionally. If you'd like to automate a push function, or just don't like to be asked twice to do something destructive, then you can opt-out.

- Default setting in Gravity Sync is `0`, change to `1` to bypass this check.

### `SKIP_CUSTOM`

Starting in v1.7.0, Gravity Sync manages the `custom.list` file that contains the "Local DNS Records" function within the Pi-hole interface. If you do not want to sync this setting, perhaps if you're doing a multi-site deployment with differing local DNS settings, then you can opt-out of this sync.

- Default setting in Gravity Sync is `0`, change to `1` to exempt `custom.list` from replication.
- This variable can be set via `./gravity-sync.sh config` function.

### `INCLUDE_CNAME`

Starting in v2.3.0, Gravity Sync manages the `05-pihole-custom-cname.conf` file that contains the "Local DNS CNAME Record" function within the Pi-hole interface. This is not enabled by default, as the file is only created if you use the feature, and since it was only added in Pi-hole 5.3, existing installations that are upgraded will not automatically enable this sync. 

You cannot enable `INCLUDE_CNAME` if you've also enabled `SKIP_CUSTOM` as the CNAME function is dependent on Local DNS records. You can, however, only replicate the Local DNS Records if you do not intend to leverage CNAME records.

- Default setting in Gravity Sync is `0`, change to `1` to include `05-pihole-custom-cname.conf` in replication.
- This variable can be set via `./gravity-sync.sh config` function.

### `DATE_OUTPUT`

_This feature has not been implemented, but the intent is to provide the ability to add timestamped output to each status indicator in the script output (ex: [2020-05-28 19:46:54] [EXEC] \$MESSAGE)._

### `PING_AVOID`

The `./gravity-sync.sh config` function will attempt to ping the remote host to validate it has a valid network connection. If there is a firewall between your hosts preventing ICMP replies, or you otherwise wish to skip this step, it can be bypassed here.

- Default setting in Gravity Sync is `0`, change to `1` to skip this network test.
- This variable can be set via `./gravity-sync.sh config` function.

### `ROOT_CHECK_AVOID`

In versions of Gravity Sync prior to 3.1, at execution, Gravity Sync would check that it's deployed with its own user (not running as root), but for some deployments this was a hindrance.

- This variable is no longer parsed by Gravity Sync.

### `BACKUP_TIMEOUT`

Allow users to adjust the time the script will wait until marking the SQLITE3 backup operation as failed. This was previously hard coded to 15 and then raised to 60, but raising it even higher has been seen to mitigate against failed replication jobs on slower SD Cards or older Raspberry Pi's where the database backup does not complete, yet still replicates.

- Default setting in Gravity Sync is `240`, adjust as desired.
- Requires Gravity Sync 3.4.1 or higher.

### `BACKUP_INTEGRITY_WAIT`

Allow users to adjust the time the script will wait until performing the SQLITE3 integrity check operation. There was previously no wait, but raising it even higher has been seen to mitigate against jobs on slower SD Cards or older Raspberry Pi's where the database backup is not fully written to disk before integrity check is attempted.

- Default setting in Gravity Sync is `5`, adjust as desired.
- Requires Gravity Sync 3.4.6 or higher.

### `SSH_PORT`

Gravity Sync is configured by default to use the standard SSH port (22) but if you need to change this, such as if you're traversing a NAT/firewall for a multi-site deployment, to use a non-standard port.

- Default setting in Gravity Sync is 22.
- This variable can be set via `./gravity-sync.sh config` function.

### `SSH_PKIF`

Gravity Sync is configured by default to use the `.ssh/id_rsa` key-file that is generated using the `ssh-keygen` command. If you have an existing key-file stored somewhere else that you'd like to use, you can configure that here. The key-file will still need to be in the users `$HOME` directory.

At this time Gravity Sync does not support using a passphrase in RSA key-files. If you have a passphrase applied to your standard `.ssh/id_rsa` either remove it, or generate a new file and specify that key for use only by Gravity Sync.

- Default setting in Gravity Sync is `.ssh/id_rsa`.
- This variable can be set via `./gravity-sync.sh config` function.

### `LOG_PATH`

Gravity Sync will place logs in the same folder as the script (identified as .cron and .log) but if you'd like to place these in a another location, you can do that by identifying the full path to the directory (ex: `/full/path/to/logs`) without a trailing slash.

- Default setting in Gravity Sync is a variable called `${LOCAL_FOLDR}`.

### `SYNCING_LOG`

Gravity Sync will write a timestamp for any completed sync, pull, push or restore job to this file. If you want to change the name of this file, you will also need to adjust the LOG_PATH variable above, otherwise your file will be remove during an `update` operations.

- Default setting in Gravity Sync is `gravity-sync.log`

### `CRONJOB_LOG`

Gravity Sync will log the execution history of the previous automation task via Cron to this file. If you want to change the name of this file, you will also need to adjust the LOG_PATH variable above, otherwise your file will be remove during an `update` operations.

This will have an impact to both the `./gravity-sync.sh automate` function and the `./gravity-sync.sh cron` functions. If you need to change this after running the automate function, either modify your crontab manually or delete the entry and re-run the automate function.

- Default setting in Gravity Sync is `gravity-sync.cron`

### `HISTORY_MD5`

Gravity Sync will log the file hashes of the previous `smart` task to this file. If you want to change the name of this file, you will also need to adjust the LOG_PATH variable above, otherwise your file will be removed during an `update` operations.

- Default setting in Gravity Sync is `gravity-sync.md5`

### `BASH_PATH`

If you need to adjust the path to bash that is identified for automated execution via Crontab, you can do that here. This will only have an impact if changed before generating the crontab via the `./gravity-sync.sh automate` function. If you need to change this after the fact, either modify your crontab manually or delete the entry and re-run the automate function.
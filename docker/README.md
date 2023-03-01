<p align="center">
<img src="https://vmstan.com/content/images/2021/02/gs-logo.svg" width="300" alt="Gravity Sync">
</p>

<span align="center">

# sync-hole: Pi-hole with gravity-sync

</span>

This docker image bundles the official [pi-hole docker image](https://github.com/pi-hole/docker-pi-hole) with [gravity-sync](https://github.com/vmstan/gravity-sync) on top as `sync-hole`.
It is a drop-in replacement for pi-hole and ideally, you just replace your existing pi-hole container with the `sync-hole` container. From inside this container you can run gravity-sync against other `sync-hole` instances or the standard gravity-sync in either direction (push, pull, auto/sync).

## Features

We bundled all features of [pi-hole](https://github.com/pi-hole/docker-pi-hole) and [gravity-sync](https://github.com/vmstan/gravity-sync) including an openssh-server in one unified docker image!
The configuration is mainly performed via the ENVs of [pi-hole](https://hub.docker.com/r/pihole/pihole) and the ones made available by [gravity-sync](../ENV.md). Keep in mind, that gravity-sync also stores settings in a `gravity-sync.conf` config-file, that always has higher priority than ENVs.

There are unique ENVs besides the one for pi-hole and gravity-sync in order to configure this container for your needs.
| Variable | Default | Value | Description |
| -------- | ------- | ----- | ---------- |
| `LOCAL_USER` | `gs` | username | SSH user to access this container via gravity-sync
| `LOCAL_PASSWORD` | unset | string | SSH password for `LOCAL_USER`. If unset, a random password will be generated everytime the container starts. See further below, on how to retrieve the temporary password.
| `PASSWORD_MIN_LEN` | `8` | integer | Minimal length for externally set static password via `LOCAL_PASSWORD`
| `GS_AUTO_MODE` | `sync` | sync-mode |  Synchroniztion mode of this container. Valid options are `sync`, `smart` (which are the same), `pull` and `push`. See more [here](https://github.com/vmstan/gravity-sync/wiki/Pull-vs-Push)
| `GS_AUTO_DELAY` | unset | minutes | If set, this will become interval for running the sync in minutes. If unset, it take value from gravity-sync.
| `GS_AUTO_JITTER` | unset | minutes | If set, this will become the additional random delay/jitter on `GS_AUTO_DELAY` to randomize sync times. Ideally, keep this below `GS_AUTO_DELAY`/2. If unset, it take value from gravity-sync.
| `GS_AUTO_DEBUG` | unset | boolean| If set to true, the synchronization will run every minute with no jitter in order to allow debugging sync easily.


## Setup Steps

### Container Preparation
Configure two (or more) `sync-hole` containers (or gravity-sync enabled hosts) as you would configure your pihole containers as described (here)[https://hub.docker.com/r/pihole/pihole]. docker-compose is highly suggested.

### Link the containers
There are several ways to link the containers.
1. Sync: When using only two containers, using `GS_AUTO_MODE`=`sync` might the most straight forward approach: Both `sync-hole` instances will respectively accept local changes and synchronizes them regularily to their remote ends. Changes on either `sync-hole` instance will be reflected on the other instance.
2. Push: Alternatively, you can define one main `sync-hole` instance which pushes (`GS_AUTO_MODE`=`push` on main) its changes to one secondary instance. Everything on the secondary instance will get overwritten by the main instance.
3. Pull: Or if you want to scale even more horizontally (one main instances, multiple secondary instances), you should configure your secondary instances with `GS_AUTO_MODE`=`pull` to pull from the main instance.

For all three possible setups, you need to link your `sync-hole` instances. How to do this is described below

#### 1.: Two pihole instances only with sync between both (both directions)
Explicitely setting `GS_AUTO_MODE`=`auto` on your `sync-hole` containers is not necessary: This is the default value after all.
You need to first retrieve the link-password from both `sync-hole` instances: `docker exec -t <sync_hole_main> cat password` and `docker exec -t <sync_hole_secondary> cat password` on their respective hosts.

Lets now start the link process from main -> secondary: If you need to specify a custom remote SSH port, replace `<SSH_PORT>` with that port. The default remote port will be `2222`.
Run `docker exec -it <sync_hole_main> gravity-sync config <SSH_PORT>` and enter the IP of the remote secondary host, then the username (Default: `gs`) and then the link password retrieved from `sync_hole_secondary`.
Now activate the sync: `docker exec -it <sync_hole_main> gravity-sync auto`

Same for linking secondary -> main:
Run `docker exec -it <sync_hole_secondary> gravity-sync config <SSH_PORT>` and enter the IP of the main remote host, then the username (Default: `gs`) and then the link password retrieved from `sync_hole_main`.
Now activate the sync: `docker exec -it <sync_hole_secondary> gravity-sync auto`

NOTE: In principle, only linking one container to the other container might be sufficient for proper syncing but keeping both containers linked to each other respectively is the best way to go.

#### 2.: Two pihole instances only with push from main to secondary
Explicitely set `GS_AUTO_MODE`=`push` on your `sync-hole` main containers.
You need to first retrieve the link-password of the secondary `sync-hole` instance: `docker exec -t <sync_hole_secondary> cat password`

Lets now start the link process from main -> secondary: If you need to specify a custom remote SSH port, replace `<SSH_PORT>` with that port. The default remote port will be `2222`.
Run `docker exec -it <sync_hole_main> gravity-sync config <SSH_PORT>` and enter the IP of the remote secondary host, then the username (Default: `gs`) and then the link password retrieved from `sync_hole_secondary`.

#### 3.: Multiple pihole instances with pull from a single main instance to multiple secondary instances
Explicitely set `GS_AUTO_MODE`=`pull` on your `sync-hole` secondary containers.
You need to first retrieve the link-password of the main `sync-hole` instance: `docker exec -t <sync_hole_main> cat password`

Lets now start the link process each secondary -> main: If you need to specify a custom remote SSH port, replace `<SSH_PORT>` with that port. The default remote port will be `2222`.
Run `docker exec -it <sync_hole_secondy_N> gravity-sync config <SSH_PORT>` and enter the IP of the remote main host, then the username (Default: `gs`) and then the link password retrieved from `sync_hole_main`.
Repeat this for all other `N` hosts of `sync_hole_secondy_N`.

## Example of two sync-hole instances (docker-compose)
Take a look at the `docker-compose.yml`. It shows you a basic configurtion for link-option 3 (above).

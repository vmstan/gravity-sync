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

### Configuration
The configuration is mainly performed via the ENVs. See the respective documatation for
1. [pi-hole](https://github.com/pi-hole/docker-pi-hole)
2. [gravity-sync](../ENV.md).

Keep in mind, that gravity-sync also stores settings in a `gravity-sync.conf` config-file, that always has higher priority than ENVs. 
This file is generated and overwritten, when you run the intial configuration (see setup below).
You can safely overwrite this file by bind-mounting it into the container to `/config/gravity-sync/gravity-sync.conf`.

The config, SSH-Keys and fingerprints used by `gravity-sync` are persistent across container updates: The folder `/config` inside the container lives on a `volume` and persists the config. If you want, you can even bind-mount to that folder `/config`.

The config of [pi-hole](https://github.com/pi-hole/docker-pi-hole) is **not** persistent across container updates: Please refere to the [pi-hole documentation](https://github.com/pi-hole/docker-pi-hole) on how to persist changes.

The following ENVs are used to further tweak this container.
| Variable           | Default | Value     | Description                                                                                                                                                                                    |
|--------------------|---------|-----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `LOCAL_USER`       | `gs`    | username  | SSH user to access this container via gravity-sync                                                                                                                                             |
| `LOCAL_PASSWORD`   | unset   | string    | SSH password for `LOCAL_USER`. If unset, a random password will be generated everytime the container starts. See further below, on how to retrieve the temporary password.                     |
| `PASSWORD_MIN_LEN` | `8`     | integer   | Minimal length for externally set static password via `LOCAL_PASSWORD`                                                                                                                         |
| `GS_AUTO_MODE`     | `sync`  | sync-mode | Synchroniztion mode of this container. Valid options are `sync`, `smart` (which are the same), `pull` and `push`. See more [here](https://github.com/vmstan/gravity-sync/wiki/Pull-vs-Push)    |
| `GS_AUTO_DELAY`    | unset   | minutes   | If set, this will become interval for running the sync in minutes. If unset, it take value from gravity-sync.                                                                                  |
| `GS_AUTO_JITTER`   | unset   | minutes   | If set, this will become the additional random delay/jitter on `GS_AUTO_DELAY` to randomize sync times. Ideally, keep this below `GS_AUTO_DELAY`/2. If unset, it take value from gravity-sync. |
| `GS_AUTO_DEBUG`    | unset   | boolean   | If set to true, the synchronization will run every minute with no jitter in order to allow debugging sync easily.                                                                              |


## Setup

### Container preparation
Configure two (or more) `sync-hole` containers (or gravity-sync enabled hosts) as you would configure your pihole containers as described [here](https://hub.docker.com/r/pihole/pihole). docker-compose is highly suggested.

### Link the containers
There are several ways to link the containers.
1. Sync: When using only two containers, using `GS_AUTO_MODE`=`sync` might the most straight forward approach: Both `sync-hole` instances will respectively accept local changes and synchronizes them regularily to their remote ends. Changes on either `sync-hole` instance will be reflected on the other instance.
2. Push: Alternatively, you can define one `main` `sync-hole` instance which pushes (`GS_AUTO_MODE`=`push` on main) its changes to one `secondary` instance. Everything on the `secondary` instance will get overwritten by the main instance.
3. Pull: If you want to scale horizontally (one `main` instances, multiple `secondary` instances), you should configure your secondary instances with `GS_AUTO_MODE`=`pull` to pull from the main instance or even build a tree-like node structure with tertiary nodes and so on.
4. A mixture of 1. and 3.: Two `main` nodes using `sync` in both directions and multiple `secondary` nodes and possibly `tertiary` nodes and so on: Your imagination is the limit!

No matter, which setup you will chose, you need to link your `sync-hole` instances and activate the sync. This requires you to interact with the nodes at least once. There are a few commands for tha you should use. Down below is a selection. In principle, all commands of `gravity-sync` are supported, but a few might be useless for the docker container setuo.
| Action               | command                                                           | Description                                                                                                                                      |
|----------------------|-------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| Get link password    | `docker exec -it <container_name> cat password`                   | Retrieves the link password required to link another container to this `<container_name>`. The password is randomly generated on container start |
| Intial configuration | `docker exec -it <container_name> gravity-sync config <SSH_PORT>` | Provisions the container for sync. Optionally, a custom `<SSH_PORT>` for the remote container to link against can be supplied                    |
| Enable sync          | `docker exec -it <container_name> gravity-sync auto`              | Enables automatic synchronization against a remote container. This `<container_name>` must be already configured                                 |
| Disable sync         | `docker exec -it <container_name> gravity-sync stop`              | Stops automatic synchronization against a remote container.                                                                                      |
| Monitor sync         | `docker exec -it <container_name> gravity-sync monitor`           | Gives live feedback about automatic backup jobs.                                                                                                 |
| Push                 | `docker exec -it <container_name> gravity-sync push`              | Pushes local changes to remote end. This `<container_name>` must be already configured                                                           |
| Pull                 | `docker exec -it <container_name> gravity-sync pull`              | Pulls remote changes to local end. This `<container_name>` must be already configured                                                            |

Explicit examples with `docker-compose.yml` code are shown below.

## Example 1: Two pihole instances with sync between both (sync = push & pull)
Set up two `sync-hole` instances, e.g. via docker-compose
Explicitely setting `GS_AUTO_MODE`=`auto` on your `sync-hole` containers is not necessary: This is the default value after all.

### `docker-compose.yml` example
```yaml
version: "2.1"
services:
  main:
    image: sync-hole
    build: .
    container_name: main
    restart: unless-stopped
    environment:
      WEBPASSWORD: "admin"
    ports:
      # Webinterface on HOST of main
      - 8080:80
    networks:
      static:
          ipv4_address: 10.0.0.101
    
  secondary:
    image: sync-hole
    build: .
    container_name: secondary
    restart: unless-stopped
    environment:
      WEBPASSWORD: "admin"
    ports:
      # Webinterface on HOST of secondary
      - 8081:80
    networks:
      static:
          ipv4_address: 10.0.0.102

#Shared network (here just for demonstration purposes)
networks:
  static:
    ipam:
      config:
        - subnet: 10.0.0.0/24
```

You then need to retrieve the link-password from both `sync-hole` instances: `docker exec -t main cat password` and `docker exec -t secondary cat password` on their respective hosts.

### Link main -> secondary: 
If you need to specify a custom remote SSH port, replace `<SSH_PORT>` with that port. The default remote port will be `2222` and must not be specified, if you use the default settings of `sync-hole`
- Run `docker exec -it main gravity-sync config <SSH_PORT>` and enter the IP of the remote `secondary` host (here: `10.0.0.102`), then the username (Default: `gs`), confirm authenticity of host by writing `yes` and then enter the link password retrieved from `secondary`.
- Now activate the sync: `docker exec -it main gravity-sync auto`

### Link secondary -> main: 
If you need to specify a custom remote SSH port, replace `<SSH_PORT>` with that port. The default remote port will be `2222` and must not be specified, if you use the default settings of `sync-hole`
- Run `docker exec -it secondary gravity-sync config <SSH_PORT>` and enter the IP of the remote `main` host (here: `10.0.0.101`), then the username (Default: `gs`), confirm authenticity of host by writing `yes` and then enter the link password retrieved from `main`.
- Now activate the sync: `docker exec -it secondary gravity-sync auto`

NOTE: In principle, only linking one container to the other container might be sufficient for proper syncing but keeping both containers linked to each other respectively is the best way to go.

## Example 2: Two pihole instances only push from main to secondary
Set up two `sync-hole` instances, e.g. via docker-compose
Explicitely set `GS_AUTO_MODE`=`push` on your `sync-hole` `main` container.

### `docker-compose.yml` example
```yaml
version: "2.1"
services:
  main:
    image: sync-hole
    build: .
    container_name: main
    restart: unless-stopped
    environment:
      WEBPASSWORD: "admin"
      GS_AUTO_MODE: "push"
    ports:
      # Webinterface on HOST of main
      - 8080:80
    networks:
      static:
          ipv4_address: 10.0.0.101
    
  secondary:
    image: sync-hole
    build: .
    container_name: secondary
    restart: unless-stopped
    environment:
      WEBPASSWORD: "admin"
    ports:
      # Webinterface on HOST of secondary
      - 8081:80
    networks:
      static:
          ipv4_address: 10.0.0.102

#Shared network (here just for demonstration purposes)
networks:
  static:
    ipam:
      config:
        - subnet: 10.0.0.0/24
```

You then need to retrieve the link-password from the `secondary` `sync-hole` instances: `docker exec -t secondary cat password`.

### Link main -> secondary: 
If you need to specify a custom remote SSH port, replace `<SSH_PORT>` with that port. The default remote port will be `2222` and must not be specified, if you use the default settings of `sync-hole`
- Run `docker exec -it main gravity-sync config <SSH_PORT>` and enter the IP of the remote `secondary` host (here: `10.0.0.102`), then the username (Default: `gs`), confirm authenticity of host by writing `yes` and then enter the link password retrieved from `secondary`.
- Now activate the sync: `docker exec -it main gravity-sync auto`

## Example 3: Multiple pihole instances with pull from a single main instance to multiple secondary instances
Set up two or more `sync-hole` instances, e.g. via docker-compose
Explicitely set `GS_AUTO_MODE`=`pull` on your `sync-hole` `secondary1`,`secondary2` and so on containers.
NOTE: You do not necessarily need to sync all `secondary` nodes against a common `main` node: You can easily build a tree with a `main` node on the root, two or more `secondary` nodes as the first leaves on `main`, which then on their own will have `tertiary` nodes as leaves and so on.

### `docker-compose.yml` example
```yaml
version: "2.1"
services:
  main:
    image: sync-hole
    build: .
    container_name: main
    restart: unless-stopped
    environment:
      WEBPASSWORD: "admin"
    ports:
      # Webinterface on HOST of main
      - 8080:80
    networks:
      static:
          ipv4_address: 10.0.0.101
    
  secondary:
    image: sync-hole
    build: .
    container_name: secondary
    restart: unless-stopped
    environment:
      WEBPASSWORD: "admin"
      GS_AUTO_MODE: "pull"
    ports:
      # Webinterface on HOST of secondary
      - 8081:80
    networks:
      static:
          ipv4_address: 10.0.0.102

#Shared network (here just for demonstration purposes)
networks:
  static:
    ipam:
      config:
        - subnet: 10.0.0.0/24

```

You then need to retrieve the link-password from the `main` `sync-hole` instances: `docker exec -t main cat password`.

### Link secondary -> main: 
If you need to specify a custom remote SSH port, replace `<SSH_PORT>` with that port. The default remote port will be `2222` and must not be specified, if you use the default settings of `sync-hole`
- Run `docker exec -it secondary gravity-sync config <SSH_PORT>` and enter the IP of the remote `main` host (here: `10.0.0.101`), then the username (Default: `gs`), confirm authenticity of host by writing `yes` and then enter the link password retrieved from `main`.
- Now activate the sync: `docker exec -it secondary gravity-sync auto`

Repeat this for all other `secondary` nodes against the `main` node.


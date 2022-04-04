The main requirement is Gravity Sync requires at least two separate Pi-hole 5.x instances. These Pi-hole instances should be already be deployed and verified to be functional, prior to the installation of Gravity Sync.

- Only the Linux distributions using systemd that Pi-hole is [certified to run on](https://docs.pi-hole.net/main/prerequesites/#supported-operating-systems) are officially supported. ([More Here](https://github.com/vmstan/gravity-sync/wiki/Frequent-Questions#do-you-support-dietpi-unraid-lxd-something-else))
- You will need a user account with operating system level administrator privileges at each side. This can be a dedicated account with `sudo` ability, or the system's `root` account. 
- If you're not using the `root` account, you can only install Gravity Sync in the user's `$HOME` directory.
- If you're not using the `root` account, make sure that the account is a member of either the `sudo` or `wheel` group on both the primary and secondary Pi-hole. Most of the pre-built images available for the Raspberry Pi already have this configured, as does Ubuntu. 
- During installation, if you're using any account other than `root`, it will be given [passwordless sudo](https://linuxize.com/post/how-to-run-sudo-command-without-password/) permissions to the system.

### Containerized Pi-hole

- Your Pi-hole installs can be a Docker container deployment as of Gravity Sync 3.1.
- Support for Podman as a container engine has been introduced starting in Gravity Sync 3.3.
- Gravity Sync will run directly on the host OS, and not inside of the container image.
- Only the [official Pi-hole Docker image](https://hub.docker.com/r/pihole/pihole) is supported.
- In addition to the officially supported Linux distributions as outlined above, when using a container engine, host OS deployments on more container oriented distributions such as [VMware Photon OS](https://vmware.github.io/photon/) may be used, so long as they’re able to run the Gravity Sync specific requirements below.

### Storage Performance

Pi-hole on its own can be abusive to SD card installs on a Raspberry Pi, due to its constant writes of logging to the disk. Gravity Sync introduces some additional storage overhead to a traditional Pi-hole environment. The replication process of the Domain Database involves:

- Performing an MD5 hash of the running database
- Taking backups of the running configuration
- Performing an SQL integrity check
- Transferring files across the network 
- Further hashing to validate replication

Also the larger your Domain Database is, the increased time it will take to perform these tasks, and perhaps additional risk of corruption due to failed replication.

When using a Raspberry Pi (or other similar device) as the primary or secondary Pi-hole target, it is suggested that you use storage media that can handle the higher IO operations. This _could_ be a high quality SD card, but an external flash drive, SSD or even a spinning disk is suggested, if available. 

If you have failed or inconsistent Gravity Sync replication sessions, that either don't complete the backup or don't pass the integrity check, this is often the root cause. 

## Required Components

The installer will perform checks to make sure the required components to use Gravity Sync (such as OpenSSH, etc) are available on both the primary and secondary Pi-hole during installation. 

- OpenSSH
- Rsync
- Git
- Sudo
- SQLite3

If any of these components are missing, you will have an opportunity to use the package manager utility that is bundled with your Linux distribution to install them. 

### Debian Based (Ubuntu, Raspbian)

```bash
apt install sqlite3 sudo git rsync ssh
```

### Redhat Based (CentOS, Fedora)

```
dnf install sqlite3 sudo git rsync ssh
```

### Photon OS

```
tdnf install sqlite3 sudo git rsync ssh
```

## Pi-hole Architecture

You will need to designate one Pi-Hole as primary and at least one as secondary.

- The primary Pi-hole is where you'll make most of your configuration changes through the Web UI, doing things such as; manual allow-listing, adding block-lists, device/group management, configuring custom/local network DNS, and changing other list settings.
- The secondary Pi-hole(s) are where you will install and configure Gravity Sync.

The primary Pi-hole will also be referred to in the interface as remote, while the secondary will be referred to as local. This is done to be as confusing as possible and make sure you read the documentation. (Just kidding) The default operation is to pull data from the primary to the secondary, and to put the operational load of Gravity Sync on what is expected to be a less active Pi-hole device.

See also: [Reference Architectures](https://github.com/vmstan/gravity-sync/wiki/Reference-Architectures)
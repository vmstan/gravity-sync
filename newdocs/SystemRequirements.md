Gravity Sync requires two Pi-hole 5.x instances running on two seperate hosts. These Pi-hole instances should be already be deployed and verified to be functional, prior to the installation of Gravity Sync. Unless otherwise specified, Gravity Sync is always developed against the latest version of Pi-hole that is generally available and expects that to be running. It is also reccomended that you validate that you're using a Linux distributions that Pi-hole is [certified to run on](https://docs.pi-hole.net/main/prerequesites/#supported-operating-systems). 

- When running Pi-hole inside of a container, only the [official Pi-hole Docker image](https://hub.docker.com/r/pihole/pihole) is supported.
- For both standard and container based Pi-hole deployments, Gravity Sync will run directly on the host OS and not inside of the container image.
- Containers must use [bind mounts](https://docs.docker.com/storage/bind-mounts/) to present the local Pi-hole configuration directories to the container, not Docker volumes.
- You can mix/match standard and container based deployments of Pi-hole, or use different underlying Linux distrobutions, in the same Gravity Sync deployment.

The Gravity Sync installer will perform checks to make sure the required components are available on your system during installation. If any of these components are missing, you will have an opportunity to use your system's package manager utility to install them. 

- Git
- OpenSSH
- Rsync

You will need a user account with operating system level administrator privileges on each Pi-hole host. This can be a dedicated account with `sudo` ability, or the system's `root` account. During installation, if you're using any account other than `root`, it will be given [passwordless sudo](https://linuxize.com/post/how-to-run-sudo-command-without-password/) permissions on the system.

### Storage Performance

Due to the nature of Pi-hole constantly writing logging to the disk, its can be abusive to the SD card of a Raspberry Pi. Gravity Sync introduces some further storage overhead. Hashing the running databases, taking backups, performing integrity checks, and transferring files between devices. The larger your Pi-hole's database is, the increased time it will take to perform these tasks, and perhaps additional risk of corruption due to failed replication.

When using a Raspberry Pi, it is suggested that you use storage media that can handle the higher IO operations. Using an dedicated USB device for storage, such a small external SSD, is highly reccomended. If you have failed or inconsistent Gravity Sync replication sessions, that either don't complete the backup or don't pass the integrity check, storage performance is often the root cause. 
In addition to any known issues outlined here, please review the [GitHub Issues](https://github.com/vmstan/gravity-sync/issues) page for real time user submitted bugs, enhancements or active/past discussions.

### Updater Issues

If the built in updater doesn't function as expected, you can manually run the git commands that operate under the covers.

```bash
git fetch --all
git reset --hard origin/master
```

If your code is still not updating after this, reinstallation is suggested rather than spending all your time troubleshooting `git` commands.

### sudo: no tty present

If you get the error `sudo: a terminal is required to read the password` or `sudo: no tty present and no askpass program specified` during your execution, make sure you have [implemented passwordless sudo](https://linuxize.com/post/how-to-run-sudo-command-without-password/), as defined in the system requirements, for the user accounts on both the local and remote systems.

### unrecognized option: preserve-status

Some minimalist Linux distributions (such as Alpine Linux) use an older version of Busybox, which misses the `--preserve-status` option on the `timeout` command. You can either update to a newer version of Busybox, or you can install the `coreutils` package in Alpine Linux, which includes a version of `timeout` which has `--preserve-status` implemented.

### Database disk image is malformed

This error has been observed mostly when Gravity Sync is running on slower SD Cards or older Raspberry Pi systems, and where the backup of the running Domain Database takes longer than expected (or never finishes) and thus when Gravity Sync replicates that copy to the secondary, it's malformed.

Starting in version 3.4.2, Gravity Sync will perform an integrity check after replication that attempt to detect this problem before completing the replication. If you see the error `Integrity check has failed for the Domain Database` this is typically why.

The suggested workaround is to move the primary (or both) of the Pi-hole installations to a storage device with more available IOPS, the alternative is to increase the timeout of the backup process from the default (60 seconds) as documented in [Hidden Figures](https://github.com/vmstan/gravity-sync/wiki/Hidden-Figures#backup_timeout).  
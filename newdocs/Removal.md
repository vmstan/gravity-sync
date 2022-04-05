# Removal

## Gravity Sync 4

Gravity Sync has a built in tool to purge everything about itself from the system. This can be used to reset a failed install, or permanently if you decide it's no longer useful for you.

```bash
gravity-sync purge
```

This will remove/disable:

- The Gravity Sync binary in `/usr/bin/gravity-sync`
- Your configuration and job history in `/etc/gravity-sync`
- All systemd automation tasks.

**This will not impact any of the Pi-hole binaries, configuration files, directories, services, etc.** Your Gravity Database, local DNS Records and local DNS CNAMEs will no longer sync, but they will be in the status they were prior to when Gravity Sync was removed.

- You will need to run the `PURGE` command on both Pi-hole instances where Gravity Sync is installed.
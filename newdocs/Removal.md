Gravity Sync has a built in tool to purge everything custom about itself from the system. This can be used to reset a failed install, or in the lead up to removing Gravity Sync completely if it's no longer useful for you.

```bash
./gravity-sync.sh purge
```

This will remove:

- All backups files.
- Your `gravity-sync.conf` file.
- All cronjob/automation tasks.
- All job history/logs.
- The SSH id_rsa keys associated with Gravity Sync.

This function will totally wipe out your existing Gravity Sync installation and reset it to the default state for the version you are running. If all troubleshooting of a bad installation fails, this is the command of last resort.

**This will not impact any of the Pi-hole binaries, configuration files, directories, services, etc.** Your Domain Database, Local DNS Records and Local DNS CNAMEs will no longer sync, but they will be in the status they were prior to when Gravity Sync was removed.

### Uninstalling

If you are completely uninstalling Gravity Sync, the last step would be to remove the `gravity-sync` folder from your installation directory.

```bash
rm -fr gravity-sync
```
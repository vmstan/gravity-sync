If you'd like to know what version of the script you have running, run the built in version checker. It will notify you if there are updates available.

```bash
./gravity-sync.sh version
```

You can then run the built-in updater to get the latest version of all the files. Both the `version` and `update` commands reach out to GitHub, so outbound access to GitHub.com is required.

```bash
./gravity-sync.sh update
```

Your copy of the `gravity-sync.conf` file, logs and backups should not be be impacted by this update, as they are specifically ignored. The main goal of Gravity Sync is to be simple to execute and maintain, so any additional requirements should also be called out when it's executed. 

After updating, be sure to manually run a `./gravity-sync.sh compare` to validate things are still working as expected.

You can run a `./gravity-sync.sh config` at any time to generate a new configuration file if you're concerned that you're missing something, especially after a major version upgrade.

- If the update script fails, make sure you did your original deployment via the online installation script or with `git clone` -- and not a manual install. Refer to [Updater Issues](https://github.com/vmstan/gravity-sync/wiki/Troubleshooting#updater-issues) or [Manual Updates](https://github.com/vmstan/gravity-sync/wiki/Under-The-Covers#manual-updates) for more details.
# Updating

## Gravity Sync 4

If you'd like to know what version of Gravity Sync you have running, run the built in version checker. It will notify you if there are updates available.

```bash
gravity-sync version
```

You can then run the built-in updater to get the latest version of all the files. Both the `version` and `update` commands reach out to GitHub, so outbound access to GitHub.com is required.

```bash
gravity-sync update
```

If the built in updater doesn't function as expected, you can reinstall Gravity Sync using the single line installer. This will make sure you have the latest copy. Your existing configuration file will not be impacted.

- Make sure to run the update command on both Gravity Sync instances.
- After updating, please run `gravity-sync compare` from each Pi-hole to validate things are still working as expected.

You can run a `gravity-sync config` at any time to generate a new configuration file if there are issues or you're concerned that you're missing something, especially after a major version upgrade.

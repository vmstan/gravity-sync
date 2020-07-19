# The Changelog

## 2.2

### The Lesser Release

This release removes support for Dropbear SSH client/server. If you are using this instead of OpenSSH (common with DietPi) please reconfigure your installation to use OpenSSH. You will want to delete your existing `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` files and run `./gravity-sync.sh configure` again to generate a new key and copy it to the primary Pi-hole.

- Updates the remote backup timeout from 15 to 60, preventing the `gravity.db` backup on the remote Pi-hole from failing. (PR [#76](https://github.com/vmstan/gravity-sync/pull/76))
- Adds `./gravity-sync.sh purge` function that will totally wipe out your existing Gravity Sync installation and reset it to the default state for the version you are running. If all troubleshooting of a bad installation fails, this is the command of last resort.

## 2.1

### The Backup Release

A new function `./gravity-sync.sh backup` will now perform a `SQLITE3` operated backup of the `gravity.db` on the local Pi-hole. This can be run at any time you wish, but can also be automated by the `./gravity-sync.sh automate` function to run once a day. New and existing users will be prompted to configure both during this task. If can also disable both using the automate function, or just automate one or the other, by setting the value to `0` during setup.

New users will automatically have their local settings backed up after completion of the initial setup, before the first run of any sync tasks.

By default, 7 days worth of backups will be retained in the `backup` folder. You can adjust the retention length by changing the `BACKUP_RETAIN` function in your `gravity-sync.conf` file. See the `ADVANCED.md` file for more information on setting these custom configuration options.

There are also enhancements to the `./gravity-sync.sh restore` function, where as previously this task would only restore the previous copy of the database that is made during sync operations, now this will ask you to select a previous backup copy (by date) and will use that file to restore. This will stop the Pi-hole services on the local server while the task is completed. After a successful restoration, you will now also be prompted to perform a `push` operation of the restored database to the primary Pi-hole server.

It's suggested to make sure your local restore was successful before completing the `restore` operation with the `push` job.

#### Deprecation

Support for the the Dropbear SSH client/server (which was added in 1.7.6) will be removed in an upcoming version of Gravity Sync. If you are using this instead of OpenSSH (common with DietPi) please reconfigure your installation to use OpenSSH. You will want to delete your existing `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` files and run `./gravity-sync.sh configure` again to generate a new key and copy it to the primary Pi-hole.

The `./gravity-sync.sh update` and `version` functions will look for the `dbclient` binary on the local system and warn users about the upcoming changes.

#### 2.1.1

- Last release was incorrectly published without logic to ignore `custom.list` if request or not used.

#### 2.1.2

- Corrects a bug in `backup` automation that causes the backup to run every minute during the hour selected.

#### 2.1.5

Skipping a few digits because what does it really matter?

- Implements a new beta branch, and with it a new `./gravity-sync.sh beta` function to enable it. This will hopefully allow new features and such to be added for test users who can adopt them and provide feedback before rolling out to the main update branch.
- Uses new SQLITE3 backup methodology introduced in 2.1, for all push/pull sync operations.
- `./gravity-sync.sh restore` lets you select a different `gravity.db` and `custom.list` for restoration.
- One new Star Trek reference.
- `./gravity-sync.sh restore` now shows recent complete Backup executions.

#### 2.1.6

- Adds prompts during `./gravity-sync.sh configure` to allow custom SSH port and enable PING avoidance.
- Adds `ROOT_CHECK_AVOID` variable to advanced configuration options, to help facilitate running Gravity Sync with container installations of Pi-hole. (PR [#64](https://github.com/vmstan/gravity-sync/pull/64))
- Adds the ability to automate automation. :mind_blown_emoji: Please see the ADVANCED.md document for more information. (PR [#64](https://github.com/vmstan/gravity-sync/pull/64))

(Thanks to [@fbourqui](https://github.com/fbourqui) for this contributions to this release.)

#### 2.1.7

- Adjusts placement of configuration import to fully implement `ROOT_CHECK_AVOID` variable.
- Someday I'll understand all these git error messages.

## 2.0

### The Smart Release

In this release, Gravity Sync will now detect not only if each component (`gravity.db` and `custom.list`) has changed since the last sync, but also what direction they need to go. It will then initiate a `push` and/or `pull` specific to each piece.

**Example:** If the `gravity.db` has been modified on the primary Pi-hole, but the `custom.list` file has been changed on the secondary, Gravity Sync will now do a pull of the `gravity.db` then push `custom.list` and finally restart the correct components on each server. It will also now only perform a sync of each component if there are changes within each type to replicate. So if you only make a small change to your Local DNS settings, it doesn't kickoff the larger `gravity.db` replication.

The default command for Gravity Sync is now just `./gravity-sync.sh` -- but you can also run `./gravity-sync.sh smart` if you feel like it, and it'll do the same thing.

This allows you to be more flexible in where you make your configuration changes to block/allow lists and local DNS settings being made on either the primary or secondary, but it's best practice to continue making changes on one side where possible. In the event there are configuration changes to the same element (example, `custom.list` changes at both sides) then Gravity Sync will attempt to determine based on timestamps on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync does not merge the contents of the files when changes happen, it simply overwrites the entire content.

New installs will use the `smart` function by default. Existing users who want to use this new method as their standard should run `./gravity-sync.sh automate` function to replace the existing automated `pull` with the new Smart Sync. This is not required. The previous `./gravity-sync.sh pull` and `./gravity-sync.sh push` commands continue to function as they did previously, with no intention to break this functionality.

#### 2.0.1

- Fixes bug that caused existing crontab entry not to be removed when switching from `pull` to Smart Sync. [#50](https://github.com/vmstan/gravity-sync/issues/50)

#### 2.0.2

- Correct output of `smart` function when script is run without proper function requested.
- Decided marketing team was correct about display of versions in `CHANGELOG.md` -- sorry Chris.
- Adds reference architectures to the `ADVANCED.md` file.
- Checks for RSYNC functionality to remote host during `./gravity-sync.sh configure` and prompts to install. [#53](https://github.com/vmstan/gravity-sync/issues/53)
- Move much of the previous `README.md` to `ADVANCED.md` file.

## 1.8

### The Logical Release

There is nothing really sexy here, but a lot of changes under the covers to improve reliability between different SSH client types. A lot of the logic and functions are more consistent and cleaner. In some cultures, fewer bugs and more reliability are considered features. Much of this will continue through the 1.8.x line.

- SSH/RSYNC connection logic rewritten to be specific to client options between OpenSSH, OpenSSH w/ SSHPASS, and Dropbear.
- Key-pair generation functions rewritten to be specific to client options, also now works with no (or at least fewer) user prompts.
- SSHPASS options should be more reliable if used, but removes messages that SSHPASS is not installed during setup, if it's not needed and Redirects user to documentation.
- Adds custom port specification to ssh-copy-id and dropbearkey commands during configuration generation.
- Generally better error handling of configuration options.

#### 1.8.1

- Detects if script is running as the root user or via `sudo ./gravity-sync.sh` and exits on error. [#34](https://github.com/vmstan/gravity-sync/issues/34)

#### 1.8.2

- Corrects issue where `custom.list` file would not replicate if the file didn't exist locally, and there were no other changes to replicate. [#39](https://github.com/vmstan/gravity-sync/issues/39)

#### 1.8.3

- Simplified method for input of automation frequency when running `./gravity-sync.sh automate` function.
- Now removes existing automation task from crontab, if it exists, when re-running `automate` function.
- Automation can be disabled by setting frequency to `0` when prompted.
- Adds `dev` tag to `./gravity-sync.sh version` output for users running off the development branch.

## 1.7

### The Andrew Release

#### Features

- Gravity Sync will now manage the `custom.list` file that contains the "Local DNS Records" function within the Pi-hole interface.
- If you do not want this feature enabled it can be bypassed by adding a `SKIP_CUSTOM='1'` to your .conf file.
- Sync will be trigged during a pull operation if there are changes to either file.

#### Known Issues

- No new Star Trek references.

#### 1.7.1

- There is a changelog file now. I'm mentioning it in the changelog file. So meta.
- `./gravity-sync.sh version` will check for and alert you for new versions.

#### 1.7.2

This update changes the way that beta/development updates are applied. To continue receiving the development branch, create an empty file in the `gravity-sync` folder called `dev` and afterwards the standard `./gravity-sync.sh update` function will apply the correct updates.

```bash
cd gravity-sync
touch dev
./gravity-sync.sh update
```

Delete the `dev` file and update again to revert back to the stable/master branch.

#### 1.7.3

- Cleaning up output of argument listing
- Removes `beta` function for applying development branch updates.

#### 1.7.4

- `./gravity-sync.sh dev` will now toggle dev flag on/off. No `touch` required, although it still works that way under the covers. Improvement of methods added in 1.7.2.
- `./gravity-sync.sh update` performs better error handling.
- Slightly less verbose in some places to make up for being more verbose in others.
- [DONE] has become [ OK ] in output.
- [INFO] header is now yellow all the way across.
- Tightens up verbiage of status messages.
- Fixes `custom.list` not being processed by `./gravity-sync.sh restore` function.
- Detects absence of `ssh` client command on host OS (DietPi)
- Detects absence of `rsync` client command on host OS (DietPi)
- Detects absence of `ssh-keygen` utility on host OS and will use `dropbearkey` as an alternative (DietPi)
- Changelog polarity reversed after heated discussions with marketing team.

#### 1.7.5

- No code changes!
- Primary README now only reflect "The Easy Way" to install and configure Gravity Sync
- "The Less Easy Way" are now part of [ADVANCED.md](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md)
- All advanced configuration options are outlined in [ADVANCED.md](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md)

#### 1.7.6

- Detects `dbclient` install as alternative to OpenSSH Client.
- Attempts to install OpenSSH Client if not found, and Dropbear is not alternative.
- Fix bug with `dropbearkey` not finding .ssh folder.
- Numerous fixes to accommodate DietPi in general.
- Fixes issue where `compare` function would show changes where actually none existed.
- [WARN] header is now purple all the way across, consistent with [INFO] as of 1.7.4.
- Fixes issue where `custom.list` would only pull if the file already existed on the secondary Pi-hole.
- One new Star Trek reference.

#### 1.7.7

- `config` function will attempt to ping remote host to validate network connection, can by bypassed by adding `PING_AVOID='1'` to your `gravity-sync.conf` file.
- Changes some [INFO] messages to [WARN] where appropriate.
- Adds aliases for more Gravity Sync functions.
- Shows current version on each script execution.
- Adds time output to Aborting message (exit without change.)
- Includes parsing of functions in time calculation.
- Checks for existence of Pi-hole binaries during validation.
- Less chatty about each step of configuration validation if it completes.
- Less chatty about replication validation if it's not necessary.
- Less chatty about file validation if no changes are required.
- When applying `update` in DEV mode, the Git branch used will be shown.
- Validates log export operation.

## 1.6

### The Restorative Release

- New `./gravity-sync.sh restore` function will bring a previous version of the `gravity.db` back from the dead.
- Changes the way that Gravity Sync prompts for data input and how confirmation prompts are handled.
- Adds ability to override verification of 'push', 'restore' or 'config' reset, see `.example` file for details.
- Five new Star Trek references.
- New functions add consistency in status output.

## 1.5

### The Automated Release

- You can now easily deploy the task automation via crontab by running `./gravity-sync.sh automate` which will simply ask how often you'd like to run the script per hour, and then create the entry for you.
- If you've already configured an entry for this manually with a prior version, the script should detect this and ask that you manually remove it or edit it via crontab -e. I'm hesitant to delete existing entries here, as it could potentially remove something unrelated to Gravity Sync.
- Changes the method for pulling development branch updates via the 'beta' function.
- Cleanup of various exit commands.

## 1.4

### The Configuration Release

- Adds new `./gravity-sync config` feature to simplify deployment!
- Adds variables for SSH settings.
- Rearranges functions, which impacts nothing.
- All new and exciting code comments.
- No new Star Trek references.

#### 1.4.1

- Adds variables for custom log locations to `gravity-sync.conf`, see `.example` file for listing.

#### 1.4.2

- Will prompt to create new `gravity-sync.conf` file when run without an existing configuration.

#### 1.4.3

- Bug fixes around not properly utilizing custom SSH key-file.

## 1.3

### The Comparison Release

1.3 should be called 2.0, but I'll resist that temptation -- but there are so many new enhancements!

- Gravity Sync will now compare remote and local databases and only replicate if it detects a difference.
- Verifies most commands complete before continuing each step to fail more gracefully.
- Additional debugging options such as checking last cronjob output via `./gravity-sync.sh cron` if configured.
- Much more consistency in how running commands are processed in interactive mode.

#### 1.3.1

- Changes [GOOD] to [DONE] in execution output.
- Better validation of initial SSH connection.
- Support for password based authentication using SSHPASS.

#### 1.3.2

- MUCH cleaner output, same great features.

#### 1.3.3

- Corrected Pihole bin path issue that cause automated sync not to reload services.

#### 1.3.4

- Moves backup of local database before initiating remote pull.
- Validates file ownership and permissions before attempting to rewrite.
- Added two Star Trek references.

## 1.2

### The Functional Release

- Refactored process to use functions and cleanup process of execution.
- Does not look for permission to update when run.
- Cleanup and expand comments.

#### 1.2.1

- Improved logging functions.

#### 1.2.2

- Different style for status updates.

#### 1.2.3

- Uses a dedicated backup folder for `.backup` and `.last` files.
- Copies db instead of moving to rename and then replacing to be more reliable.
- Even cleaner label status.

#### 1.2.4

- Changes `~` to `$HOME`.
- Fixes bug that prevented sync from working when run via crontab.

#### 1.2.5

- Push function now does a backup, on the secondary PH, of the primary database, before pushing.

## 1.1

### The Pushy Release

- Separated main purpose of script into `pull` argument.
- Allow process to reverse back using `push` argument.

#### 1.1.2

- First release since move from being just a Gist.
- Just relearning how to use GitHub, minor bug fixes.

#### 1.1.3

- Now includes example an configuration file.

#### 1.1.4

- Added update script.
- Added version check.

#### 1.1.5

- Added ability to view logs with `./gravity-sync.sh logs`.

#### 1.1.6

- Code easier to read with proper tabs.

## 1.0

### The Initial Release

No version control, variables or anything fancy. It only worked if everything was exactly perfect.

```bash
echo 'Copying gravity.db from HA primary'
rsync -e 'ssh -p 22' ubuntu@192.168.7.5:/etc/pihole/gravity.db /home/pi/gravity-sync
echo 'Replacing gravity.db on HA secondary'
sudo cp /home/pi/gravity-sync/gravity.db /etc/pihole/
echo 'Reloading configuration of HA secondary FTLDNS from new gravity.db'
pihole restartdns reload-lists
```

For real, that's it. 6 lines, and could probably have be done with less.

# The Changelog

## 3.3

### The Podman Release

For this release, "beta" support for [Podman](https://podman.io) based container deployments has been added. (Thanks to work by [@mfschumann](https://github.com/vmstan/gravity-sync/pull/138)) This is marked as beta because at the moment, Gravity Sync may not be regularly tested with this container engine and so regular support may be limited. Use of the official Pi-hole container image is still required.

This release also removes automated nightly backups as a function of the automation script. You can still execute a manual `./gravity-sync.sh backup` anytime. Automating this function was made redundant by the primary synchronization functions backing up the database files prior to execution in later versions, resulting in multiple backups or backing up unchanged data. Existing users will continue to backup each night unless you run `./gravity-sync.sh automate` again to configure a new schedule, at which time the existing backup job will be deleted.

Additionally, this release focuses on making some of the prompts and messages in Gravity Sync easier to understand. Starting with the initial install and configuration wizard. As the script has grown, added features, and become more complex... more options are necessary during install and it wasn't always clear what to do. This release adds some clarification to various components and will change over time.

#### Configuration Changes

- The first time you execute Gravity Sync after upgrading to 3.3, your `gravity-sync.conf` file will be moved into a `settings` folder in the same directory.
- The first time you execute Gravity Sync after upgrading to 3.3, your existing `gravity-sync.md5`, `gravity-sync.log`, and `gravity-sync.cron` files will be moved into a `logs` folder in the same directory.
- The default number days for which backups are retained has been reduced from 7 to 3.

#### Bug Fixes

- Docker Swarm use for the Pi-hole container should be supported by a change in the execution command.

## 3.2

### The Alias Release

This release now fully supports Pi-hole 5.2, specifically the CNAME replication features that were added. Because the location of these settings is in a new directory that was not previously monitored by Gravity Sync, you will need to opt-in to replication by updating your configuration file to enable support for replicating this.

- New setups can be prompted to enable this during configuration using the Advanced Configuration options.
- Existing installs wishing to make sure of this feature, should either re-run the `./gravity-sync config` command, or manually edit the `gravity-sync.conf` to set `INCLUDE_CNAME='1'`.
- Before you enable `INCLUDE_CNAME` make sure you've created at least one entry from within the primary Pi-hole interface, otherwise Gravity Sync will have nothing to replicate as the files will not yet exist.
- You cannot enable `INCLUDE_CNAME` if you've also enabled `SKIP_CUSTOM` as the CNAME function is dependent on Local DNS records. You can, however, only replicate the Local DNS Records if you do not intend to leverage CNAME records.
- Existing installs using Docker, or otherwise using a non-standard location for dnsmasq configuration files (default is `/etc/dnsmasq.d`) will also need to manually specify the location of these files.
- See the [Hidden Figures](https://github.com/vmstan/gravity-sync/wiki/Hidden-Figures) document for more details.

#### More Syncing Coming

Even before the Pi-hole team added the CNAME feature and implemented in such a way that the `/etc/dnsmasq.d` would need to be seen by Gravity Sync, I have had a desire to replicate additional custom files here for my own selfish needs. More people asked for a similar function, and now that it's required to be built into the core script, it's easier to include these additional files.

Not implemented in 3.2.0, but coming within this release, Gravity Sync will be configured to monitor a custom file of your creation in this folder (default is `08-gs-lan.conf`) which can contain additional configuration options for DNSMASQ.

An example would be setting different caching options for Pi-hole, or specifying the lookup targets for additional networks. Similar requirements as above for the CNAME syncing must be met for existing installs to leverage this functionality.

#### 3.2.1

- Changes application of permissions for Docker instances to UID:GID instead of names. (#99/#128)
- Adds `./gravity-sync.sh info` function to help with troubleshooting installation/configuration settings.

#### 3.2.2

The `./gravity-sync.sh restore` process completely revamped:

- You can now choose to ignore any of the three elements during restore.
- The prompts are clearer and more consistent with Gravity Sync script styling.
- Importantly, lack of backup files in an element will not cause the restoration to fail.

#### 3.2.3

- Cleanup of the error message screen when an invalid command is run (ex: `./gravity-sync.sh wtf`)

#### 3.2.4

- Changes script startup and shutdown text format.

#### 3.2.5

- Correct error where Docker based installs would fail to restart if Docker exec commands required sudo privileges.
- Correct error where setup script would prompt twice for Local/Remote DNSMASQ directories when using Docker.

#### 3.2.6

- Adds old backup removal tasks into push/pull/sync/compare functions.

## 3.1

### The Container Release

The premise of this release was to focus on adding better support for Docker container instances of Pi-hole. This release also changes a lot of things about the requirements that Gravity Sync has always had, which were not running as the root user, and requiring that the script be run from the user's home directory. Those two restrictions are gone.

You can now use a standard Pi-hole install as your primary, or your secondary. You can use a Docker install of Pi-hole as your primary, or your secondary. You can mix and match between the two however you choose. You can have Pi-hole installed in different directories at each side, either as standard installs or with container configuration files in different locations. Overall it's much more flexible.

#### Docker Support

- Only the [official Pi-hole managed Docker image](https://hub.docker.com/r/pihole/pihole) is supported. Other builds may work, but they have not been tested.
- If you are using a name for your container other than the default `pihole` in your Docker configuration, you must specify this in your `gravity-sync.conf` file.
- Smart Sync, and the associated push/pull operations, now will send exec commands to run Pi-hole restart commands within the Docker container.
- Your container configuration must expose access to the virtual `/etc/pihole` location to the host's file system, and be configured in your `gravity-sync.conf` file.

**Example:** if your container configuration looked something like like `-v /home/vmstan/etc-pihole/:/etc/pihole` then the location `/home/vmstan/etc-pihole` would need to be accessible by the user running Gravity Sync, and be configured as the `PIHOLE_DIR` (or `RIHOLE_DIR`) in your `gravity-sync.conf` file.

#### Installation Script

- Detects the running instance of default Pi-hole Docker container image, if standard Pi-hole lookup fails. Pi-hole must still be installed prior to Gravity Sync.
- Changes detection of root vs sudo users, and adapts commands to match. You no longer need to avoid running the script as `root`.
- Only deploys passwordless SUDO components if deemed necessary. (i.e. Not running as `root`.)
- Now automatically runs the local configuration function on the secondary Pi-hole after execution.
- Deploys script via `git` to whatever directory the installer runs in, instead of defaulting to the user's `$HOME` directory.
- Gravity Sync no longer requires that it be run from the user's `$HOME` directory.

#### Configuration Workflow

- Overall, a simpler configuration function, as the online installer now checks for the dependencies prior to execution.
- New users with basic Pi-hole installs will only be prompted for the address of the primary (remote) Pi-hole, an SSH user and then the SSH password to establish a trusted relationship and share the keyfiles.
- Automatically prompts on during setup to configure advanced variables if a Docker installation is detected on the secondary (local) Pi-hole.
- Advanced users can set more options for non-standard deployments at installation. If you are using a Docker deployment of Pi-hole on your primary (remote) Pi-hole, but not the system running Gravity Sync, you will need to enter this advanced mode when prompted.
- Existing users with default setups should not need to run the config utility again after upgrading, but those with custom installs (especially existing container users) should consider it to adopt new variable names and options in your config files.
- Creates a BASH environment alias to run the command `gravity-sync` from anywhere on the system. If you use a different shell (such as zsh or fish) as your default this may need to be added manually.

#### New Variables

- `REMOTE_FILE_OWNER` variable renamed `RILE_OWNER` for consistency.
- `RIHOLE_DIR` variable added to set different Pi-hole directory for remote host than local.
- `DOCKER_CON` and `ROCKER_CON` variables added to specify different names for local and remote Pi-hole Docker containers.
- `PH_IN_TYPE` and `RH_IN_TYPE` variables allow you to to either standard or Docker deployments of Pi-hole, per side.
- `DOCKER_BIN` and `ROCKER_BIN` variables allow you to set non-standard locations for Docker binary files, per side.
- Adds all variables to `gravity-sync.conf.example` for easy customization.

#### Removals

- Support for `sshpass` has been removed, the only valid authentication method going forward will be ssh-key based.
- If you've previously configured Gravity Sync using `sshpass` you will need to run `./gravity-sync.sh config` again to create a new configuration file.

#### Bug Killer

- Lots of long standing little buggles have been squashed.

#### Branding

- I made a logo.

<img src="https://raw.githubusercontent.com/vmstan/gravity-sync/master/docs/gs-logo.svg" height="150" width="150" alt="Gravity Sync">

#### 3.1.1

- Corrected an error where Docker exec commands would not run correctly on some distributions.

#### 3.1.2

- Fix variable missing quotes error in configuration screen.
- Convert all bash files from mix of tabs and spaces to 4 space indentation.

## 3.0

### The Breakout Release

This release focuses on breaking out elements of the script from the main file into a collection of a dozen or so files located under the `includes/gs-*.sh` hirearchy. Seperating out allows new contributors to work on different parts of the script individually, provides an oppertunity to clean up and reorganize parts of the code, and hopefully provides less risk of breaking the entire script.

This release also features a brand new installation script, including a host check for both the primary and secondary Pi-hole system. This should reduce frustration of users who are missing parts of the system requirements. This will also place a file in the sudoers.d file on both systems to make sure passwordless sudo is configured as part of the installation.

Lastly, we adopts Pi-hole style iconography such as `✓ ✗ e ! ?` instead of `[ GOOD ]` in command output.

Enjoy!

#### 3.0.1

- `dev` function now automatically updates Gravity Sync after application.
- `dev` function pulls new branches down before prompting to select which one to update against.
- Minor shuffle of `gravity-sync.sh` contents.
- Clarify installation requirements in `README.md`.
- Fixes issues with permissions on `gravity.db` after push operations.
- Fixes missing script startup output during `dev` operation.

#### 3.0.2

- Realigned EPS conduits, they overheat if you leave them pointed the same way for too long.
- Corrected error when running via crontab where includes directory was not properly sourced.

## 2.2

### The Purged Release

This release removes support for Dropbear SSH client/server. If you are using this instead of OpenSSH (common with DietPi) please reconfigure your installation to use OpenSSH. You will want to delete your existing `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` files and run `./gravity-sync.sh configure` again to generate a new key and copy it to the primary Pi-hole.

This release also adds the `./gravity-sync.sh purge` function that will totally wipe out your existing Gravity Sync installation and reset it to the default state for the version you are running. If all troubleshooting of a bad installation fails, this is the command of last resort.

- Updates the remote backup timeout from 15 to 60, preventing the `gravity.db` backup on the remote Pi-hole from failing. (PR [#76](https://github.com/vmstan/gravity-sync/pull/76))
- Adds uninstall instructions to the README.md file. (Basically, run the new `purge` function and then delete the `gravity-sync` folder.)
- I found a markdown spellcheck utility for Visual Studio Code, and ran it against all my markdown files. I'm sorry, I don't spell good. 🤷‍♂️
- New Star Trek references.

#### 2.2.1

- Corrects issue with Smart Sync where it would fail if there was no `custom.list` already present on the local Pi-hole.
- Adds Pi-hole default directories to `gravity-sync.conf.example` file.
- Adds `RIHOLE_BIN` variable to specify different Pi-hole binary location on remote server.

#### 2.2.2

- Corrects another logical problem that prevented `custom.list` from being backed up and replicated, if it didn't already exist on the local Pi-hole.

#### 2.2.3

- Adds variable to easily override database/binary file owners, useful for container deployments. (Thanks @dpraul)
- Adds variable to easily override Pi-hole binary directory for remote host, seperate from local host. (Thanks @dpraul)
- Rewritten `dev` option now lets you select the branch to pull code against, allowing for more flexibility in updating against test versions of the code. The `beta` function introduced in 2.1.5 has now been removed.
- Validates existance of SQLite installation on local Pi-hole.
- Adds Gravity Sync permissions for running user to local `/etc/sudoer.d` file during `config` operation.
- Adds `./gravity-sync.sh sudo` function to create above file for existing setups, or to configure the remote Pi-hole by placing the installer files on that system. This is not required for existing functional installs, but this should also negate the need to give the Gravity Sync user NOPASSWD permissions to the entire system.

## 2.1

### The Backup Release

A new function `./gravity-sync.sh backup` will now perform a `SQLITE3` operated backup of the `gravity.db` on the local Pi-hole. This can be run at any time you wish, but can also be automated by the `./gravity-sync.sh automate` function to run once a day. New and existing users will be prompted to configure both during this task. If can also disable both using the automate function, or just automate one or the other, by setting the value to `0` during setup.

New users will automatically have their local settings backed up after completion of the initial setup, before the first run of any sync tasks.

By default, 7 days worth of backups will be retained in the `backup` folder. You can adjust the retention length by changing the `BACKUP_RETAIN` function in your `gravity-sync.conf` file. See the `ADVANCED.md` file for more information on setting these custom configuration options.

There are also enhancements to the `./gravity-sync.sh restore` function, where as previously this task would only restore the previous copy of the database that is made during sync operations, now this will ask you to select a previous backup copy (by date) and will use that file to restore. This will stop the Pi-hole services on the local server while the task is completed. After a successful restoration, you will now also be prompted to perform a `push` operation of the restored database to the primary Pi-hole server.

It's suggested to make sure your local restore was successful before completing the `restore` operation with the `push` job.

#### Dropbear Notice

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

- Corrected Pi-hole bin path issue that cause automated sync not to reload services.

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

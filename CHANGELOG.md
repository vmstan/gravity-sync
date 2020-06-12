# The Changelog

## 1.8
### The Logical Release

**Features**
There is nothing really sexy here, but a lot of changes under the covers to improve reliablity between different SSH client types. A lot of the logic and functions are more consistent and cleaner. In some cultures, fewer bugs and more reliablity are considered features. Much of this will continue through the 1.8.x line.

- SSH/RSYNC connection logic rewritten to be specific to client options between OpenSSH, OpenSSH w/ SSHPASS, and Dropbear.
- Key-pair generation functions rewritten to be specific to client options, also now works with no (or at least fewer) user prompts.
- SSHPASS options should be more reliable if used, but removes messages that SSHPASS is not installed during setup, if it's not needed and Redirects user to documentation.
- Adds custom port specification to ssh-copy-id and dropbearkey commands during configuration generation.
- Generally better error handling of configuration options.

#### 1.8.2
- Corrects issue where `custom.list` file would not replicate if the file didn't exist locally, and there were no other changes to replicate. [#39](https://github.com/vmstan/gravity-sync/issues/39)

#### 1.8.1
- Detects if script is running as the root user or via `sudo ./gravity-sync.sh` and exits on error. [#34](https://github.com/vmstan/gravity-sync/issues/34)

## 1.7
### The Andrew Release

**Features**
- Gravity Sync will now manage the `custom.list` file that contains the "Local DNS Records" function within the Pi-hole interface.
- If you do not want this feature enabled it can be bypassed by adding a `SKIP_CUSTOM='1'` to your .conf file. 
- Sync will be trigged during a pull operation if there are changes to either file.

**Known Issues**
- No new Star Trek references.

#### 1.7.7
- `config` function will attempt to ping remote host to validate network connection, can by bypassed by adding `PING_AVOID='1'` to your `gravity-sync.conf` file.
- Changes some [INFO] messages to [WARN] where approprate.
- Adds aliases for more Gravity Sync functions.
- Shows current version on each script execution.
- Adds time output to Aborting message (exit without change.)
- Includes parsing of functions in time calculation.
- Checks for existance of Pi-hole binaries during validation.
- Less chatty about each step of configuration validation if it completes.
- Less chatty about replication validation if it's not necessary.
- Less chatty about file validation if no changes are required.
- When applying `update` in DEV mode, the Git branch used will be shown.
- Validates log export operation.

#### 1.7.6
- Detects `dbclient` install as alternative to OpenSSH Client.
- Attempts to install OpenSSH Client if not found, and Dropbear is not alternative.
- Fix bug with `dropbearkey` not finding .ssh folder.
- Numerous fixes to accomidate DietPi in general.
- Fixes issue where `compare` function would show changes where actually none existed.
- [WARN] header is now purple all the way across, consistent with [INFO] as of 1.7.4.
- Fixes issue where `custom.list` would only pull if the file already existed on the secondary Pi-hole.
- One new Star Trek reference.

#### 1.7.5
- No code changes!
- Primary README now only reflect "The Easy Way" to install and configure Gravity Sync
- "The Less Easy Way" are now part of [ADVANCED.md](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md)
- All advanced configuration options are outlined in [ADVANCED.md](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md)

#### 1.7.4
- `./gravity-sync.sh dev` will now toggle dev flag on/off. No `touch` required, although it still works that way under the covers. Improvement of methods added in 1.7.2.
- `./gravity-sync.sh update` performs better error handling.
- Slightly less verbose in some places to make up for being more verbose in others.
- [DONE] has become [ OK ] in output.
- [INFO] header is now yellow all the way across.
- Tightens up verbage of status messages.
- Fixes `custom.list` not being processed by `./gravity-sync.sh restore` function.
- Detects absence of `ssh` client command on host OS (DietPi)
- Detects absence of `rsync` client command on host OS (DietPi)
- Detects absence of `ssh-keygen` utility on host OS and will use `dropbearkey` as an alternative (DietPi)
- Changelog polarity reversed after heated discussions with marketing team.

#### 1.7.3
- Cleaning up output of argument listing

#### 1.7.2
This update changes the way that beta/development updates are applied. To continue receving the development branch, create an empty file in the `gravity-sync` folder called `dev` and afterwards the standard `./gravity-sync.sh update` function will apply the correct updates.
```
cd gravity-sync
touch dev
./gravity-sync.sh update
```
Delete the `dev` file and update again to revert back to the stable/master branch.

**Deprecation**
- Removes `beta` function for applying development branch updates.

#### 1.7.1
- There is a changelog file now. I'm mentioning it in the changelog file. So meta.
- `./gravity-sync.sh version` will check for and alert you for new versions.

## 1.6
### The Restorative Release

**Features**
- New `./gravity-sync.sh restore` function will bring a previous version of the `gravity.db` back from the dead.
- Changes the way that Gravity Sync prompts for data input and how confirmation prompts are handled.
- Adds ability to override verification of 'push', 'restore' or 'config' reset, see `.example` file for details.
- Five new Star Trek references.

**Bug Fixes**
- New functions add consistency in status output.

## 1.5
### The Automated Release

**Features**
- You can now easily deploy the task automation via crontab by running `./gravity-sync.sh automate` which will simply ask how often you'd like to run the script per hour, and then create the entry for you.
- If you've already configured an entry for this manually with a prior version, the script should detect this and ask that you manually remove it or edit it via crontab -e. I'm hesitant to delete existing entries here, as it could potentially remove something unrelated to Gravity Sync.

**Bug Fixes**

- Changes the method for pulling development branch updates via the 'beta' function.
- Cleanup of various exit commands.

## 1.4
### The Configuration Release

**Features**
- Adds new `./gravity-sync config` feature to simplify deployment!
- Adds variables for SSH settings.
- Rearranges functions, which impacts nothing.
- All new and exciting code comments.
- No new Star Trek references.

#### 1.4.3
- Bug fixes around not properly utilizing custom SSH keyfile.

#### 1.4.2
- Will prompt to create new `gravity-sync.conf` file when run without an existing configuration.

#### 1.4.1
- Adds variables for custom log locations to `gravity-sync.conf`, see `.example` file for listing.

## 1.3
### The Comparison Release
1.3 should be called 2.0, but I'll resist that temptation -- but there are so many new enhancements!

**Features**
- Gravity Sync will now compare remote and local databases and only replicate if it detects a difference.
- Verifies most commands complete before continuing each step to fail more gracefully.
- Additional debugging options such as checking last cronjob output via `./gravity-sync.sh cron` if configured.
- Much more consistency in how running commands are processed in interactive mode.

#### 1.3.4
- Moves backup of local database before initiating remote pull.
- Validates file ownership and permissions before attempting to rewrite.
- Added two Star Trek references.

#### 1.3.3
- Corrected Pihole bin path issue that cause automated sync not to reload services.

#### 1.3.2
- MUCH cleaner output, same great features.

#### 1.3.1
- Changes [GOOD] to [DONE] in execution output.
- Better validation of initial SSH connection.
- Support for password based authentication using SSHPASS.


## 1.2
### The Functional Release
- Refactored process to use functions and cleanup process of execution.
- Does not look for permission to update when run.
- Cleanup and expand comments.

#### 1.2.5
- Push function now does a backup, on the secondary PH, of the primary database, before pushing.

#### 1.2.4
- Changes `~` to `$HOME`.
- Fixes bug that prevented sync from working when run via crontab.

#### 1.2.3
- Uses a dedicated backup folder for `.backup` and `.last` files.
- Copies db instead of moving to rename and then replacing to be more reliable.
- Even cleaner label status.

#### 1.2.2
- Different style for status updates.

#### 1.2.1
- Improved logging functions.

## 1.1
### The Pushy Release

- Seperated main purpose of script into `pull` argument.
- Allow process to reverse back using `push` argument.

#### 1.1.6
- Code easier to read with proper tabs.

#### 1.1.5
- Added ability to view logs with `./gravity-sync.sh logs`.

#### 1.1.4
- Added update script.
- Added version check.

#### 1.1.3
- Now includes example an configuration file.

#### 1.1.2
- First release since move from being just a Gist.
- Just relearning how to use GitHub, minor bug fixes.

## 1.0
### The Initial Release

No version control, variables or anything fancy. It only worked if everything was exactly perfect.

```
echo 'Copying gravity.db from HA primary'
rsync -e 'ssh -p 22' ubuntu@192.168.7.5:/etc/pihole/gravity.db /home/pi/gravity-sync
echo 'Replacing gravity.db on HA secondary'
sudo cp /home/pi/gravity-sync/gravity.db /etc/pihole/ 
echo 'Reloading configuration of HA secondary FTLDNS from new gravity.db'
pihole restartdns reload-lists
```

For real, that's it. 6 lines, and could probably have be done with less.
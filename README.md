<p align="center">
	<img src="https://raw.githubusercontent.com/vmstan/gravity-sync/master/docs/gravity-header.svg" width="80%" alt="Gravity Sync">
</p>

What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking ads via DNS on your network? That's right, two Pi-hole blocking ads on your network!

But if you have more than one Pi-hole in your network you'll want a simple way to keep the list configurations and local DNS settings identical between the two. That's Gravity Sync.

## Features

Gravity Sync will:

- Sync the Adlist database (allow/block list) configurations stored in `gravity.db` between multiple Pi-hole.
- Sync the Local DNS Settings stored in `custom.list` between multiple Pi-hole.
- Provide an easy way to keep this happening in the background.

Ideally you set up Gravity Sync and forget about it -- and in the long term, it would be awesome if the Pi-hole team made this entire script unnecessary.

### Limitations

Gravity Sync will **not**:

- Overwrite individual Pi-hole specific settings such as the device's network configuration, admin/API passwords/keys, upstream DNS resolvers, etc.
- Keep DHCP settings or device leases synchronized.

### Disclaimer

Gravity Sync is not developed by or affiliated with the Pi-hole project. This is an effort that seeks to implement replication, which is currently not a part of the core Pi-hole product. The code has been tested across multiple user environments but there always is an element of risk involved with running any arbitrary software you find on the Internet.

## Setup Steps

1. Read the installation Requirements!
2. Prepare your Pi-hole hosts.
3. Install Gravity Sync to your secondary Pi-hole.
4. Configure your Gravity Sync installation.
5. Test your Gravity Sync install.
6. Automate future synchronizations.
7. Profit.

## Requirements

- Pi-hole 5.0 (or higher) must already be installed on at least two systems, using any of the Linux distributions that Pi-hole is [certified to run on](https://docs.pi-hole.net/main/prerequesites/#supported-operating-systems).
- As of Gravity Sync 3.1, your Pi-hole installs can be a standard installation of Pi-hole or a Docker container deployment. In either case, Gravity Sync will run directly on the host OS, and not inside of a container image.
- If you are using containerized deployments of Pi-hole, only the [official Pi-hole Docker image](https://hub.docker.com/r/pihole/pihole) is supported.
- You will need a user account with local administrator privileges on the host OS at each side. This can be a dedicated account or the system's `root` account. If you're not the `root` account, you can only install in the user's `$HOME` directory.
- If you're using a non-root user, make sure that the account is a member of the `sudo` group on both the primary and secondary Pi-hole. Most of the pre-built images available for the Raspberry Pi already have this configured, as does Ubuntu. During installation this user will be given passwordless sudo permissions to the system.
- The installer will perform checks to make sure the required components to use Gravity Sync such as OpenSSH `ssh`, `SQLite3`, and `rsync` (plus a few others) are available on both the primary and secondary Pi-hole during installation. If they are missing you will have an opportunity to use whatever package manager is available on your system to correct the missing dependencies. These binaries are what do the heavy lifting between your Pi-hole nodes.

### Pi-hole Architecture

You will want to designate one Pi-Hole as primary and at least one as secondary.

- The primary Pi-hole is where you'll make most of your configuration changes through the Web UI, doing things such as; manual allow-listing, adding block-lists, device/group management, configuring custom/local network DNS, and changing other list settings.
- The secondary Pi-hole(s) are where you will install and configure Gravity Sync.

For more information and for reference architectures, please [refer to this document](https://github.com/vmstan/gravity-sync/blob/master/docs/ADVANCED.md#reference-architectures)

## Installation

### Primary Pi-Hole

Minimal preperation is required on your primary Pi-hole, the installer will mostly check that all dependencies have been met for use.

Login to your _primary_ Pi-hole, and run the following command:

```bash
export GS_INSTALL=primary && curl -sSL https://raw.githubusercontent.com/vmstan/gravity-sync/master/prep/gs-install.sh | bash
```

This will verify you have everything necessary to use Gravity Sync. It will also add a passwordless sudo configuration file for the current user. The installer will then exit, and direct you to proceed to the secondary Pi-hole.

After you have completed this step, log out of the _primary_ Pi-hole.

### Secondary Pi-Hole

From this point forward, all operations will take place on your secondary Pi-hole.

Login to your _secondary_ Pi-hole, and run the following command:

```bash
export GS_INSTALL=secondary && curl -sSL https://raw.githubusercontent.com/vmstan/gravity-sync/master/prep/gs-install.sh | bash
```

This will verify you have everything necessary to use Gravity Sync. The installer will then use Git to make a copy of the Gravity Sync executables in the folder the installer was executed in, and direct you to proceed to Configuration step below. Once this has completed, you will now have a folder called `gravity-sync` in your installed directory. Everything Gravity Sync runs from there.

Proceed to the Configuration section.

## Configuration

After you install Gravity Sync to your _secondary Pi-hole_ you will need to create a configuration file. This will run automatically by the installer.

This will guide you through the process of:

- Specifying the IP or DNS name of your primary Pi-hole.
- Specifying the SSH username to connect to your primary Pi-hole.
- Configuring your key-pair and applying it to your primary Pi-hole.

The configuration will be saved as `gravity-sync.conf` in the same folder as the script. If you need to make adjustments to your settings in the future, you can edit this file or run the configuration tool to generate a new one.

If you are deploying Gravity Sync to a system using Docker containers, the script should detect this and prompt for additional configuration. You can also choose to perform an advanced installation when prompted.

After you're pleased with your configuration, proceed to the Execution phase.

## Execution

Now, test Gravity Sync. You can run a comparison between primary and secondary databases, which will be non-disruptive, and see if everything has been configured correctly.

```bash
./gravity-sync.sh compare
```

Assuming Gravity Sync runs successfully, it will indicate if there are changes pending between the two databases. If not, make a subtle change to a allow/block list on your primary Pi-hole, such as changing a description field or disabling a allow list item, and then running `./gravity-sync.sh compare` again to validate your installation is working correctly.

### The Sync

The default command for Gravity Sync is simple.

```bash
./gravity-sync.sh
```

But you can also run `./gravity-sync.sh smart` if you feel like it, and it'll do the same thing.

Gravity Sync will perform some checks to help ensure success and then stop before making changes if it detects an issue. It will also perform the same `compare` function outlined above, and if there are no changes pending, it will exit without making an attempt to copy data.

**Example:** If the `gravity.db` has been modified on the primary Pi-hole, but the `custom.list` file has been changed on the secondary, Gravity Sync will now do a pull of the `gravity.db` then push `custom.list` and finally restart the correct components on each server. It will also now only perform a sync of each component if there are changes within each type to replicate. So if you only make a small change to your Local DNS settings, it doesn't kickoff the larger `gravity.db` replication.

This allows you to be more flexible in where you make your configuration changes to block/allow lists and local DNS settings being made on either the primary or secondary, but it's best practice to continue making changes on one side where possible. In the event there are configuration changes to the same element (example, `custom.list` changes at both sides) then Gravity Sync will attempt to determine based on timestamps on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync does not merge the contents of the files when changes happen, it simply overwrites the entire content.

If the execution completes, you will now have a synchronized copy of your running `gravity.db` and `custom.list` on the both Pi-hole after creating a time-stamped copy of the running files (with `.backup` appended) in the `backup` subfolder located with your script, on the secondary Pi-hole.

Finally, a file called `gravity-sync.log` will be created in the `gravity-sync` folder along side the script with the date the script was last executed appended to the bottom.

You can check for successful pull attempts by running: `./gravity-sync.sh logs`

## Automation

Automation of sync is accomplished by adding an execution of the script to the user's crontab file. As Gravity Sync won't make any changes if it doesn't detect a difference to sync, then the impact should be minor to your systems.

```bash
./gravity-sync.sh automate
```

Select the frequency per hour (in minutes) that you'd like to sync and that's it.

Now, make another small adjustment to your primary settings and wait until anointed time to see if your changes have been synchronized. If so, profit! If not, start from the beginning. From this point forward any block list changes you make to the primary will reflect on the secondary within the frequency you select.

If you'd like to see the log of what was run the last crontab, you can view that output by running:

```bash
./gravity-sync.sh cron
```

Keep in mind if your cron task has never run, you will not see any valid output from this command.

### Adjusting Automation

You can verify your existing automation entry by running `crontab -l` and see it listed at the bottom of the crontab file. If you decide to remove or change your frequency (as of version 1.8.3) you can run `./gravity-sync.sh automate` again and pick a new timing, including setting it to 0 to disable automation.

## Updates

If you'd like to know what version of the script you have running, check the built in version checker. It will notify you if there are updates available.

```bash
./gravity-sync.sh version
```

You can then run the built-in updater to get the latest version of all the files. Both the `version` and `update` commands reach out to GitHub, so outbound access to GitHub.com is required.

```bash
./gravity-sync.sh update
```

Your copy of the `gravity-sync.conf` file, logs and backups should not be be impacted by this update, as they are specifically ignored. The main goal of Gravity Sync is to be simple to execute and maintain, so any additional requirements should also be called out when it's executed. After updating, be sure to manually run a `./gravity-sync.sh compare` or `./gravity-sync.sh pull` to validate things are still working as expected.

You can run a `./gravity-sync.sh config` at any time to generate a new configuration file if you're concerned that you're missing something.

- If the update script fails, make sure you did your original deployment via `git clone` and not a manual install. Refer to [ADVANCED.md](https://github.com/vmstan/gravity-sync/blob/master/docs/ADVANCED.md) for more details.

## Starting Over

Gravity Sync has a built in tool to purge everything custom about itself from the system.

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

**This will not impact any of the Pi-hole binaries, configuration files, directories, services, etc.** Your Adlist database and Local Custom DNS records will no longer sync, but they will be in the status they were when Gravity Sync was removed.

### Uninstalling

If you are completely uninstalling Gravity Sync, the last step would be to remove the `gravity-sync` folder from your installation directory.

## Advanced Installation

Please review the [Advanced Installation](https://github.com/vmstan/gravity-sync/blob/master/docs/ADVANCED.md) guide for more assistance.

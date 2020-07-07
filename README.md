# Gravity Sync
## Background
What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking ads via DNS on your network? That's right, Two Pi-hole! But if you have more than one Pi-hole in your network you'll want a simple way to keep the list configurations identical between the two.

That's Gravity Sync.

At it's core, Gravity Sync is maybe a handful of core bash commands, that uses rsync to reach out to a remote host, copy the running `gravity.db` file that contains the Pi-hole blocklist, as well as the `custom.list` file that contains local DNS enteries, and then replaces the copy on the local system. What Gravity Sync provides is an easy way to keep this happening in the background. Ideally you set it and forget it and in the long term, it would be awesome if the Pi-hole team made this entire script unncessary.

Gravity Sync will **not** overwrite device specific settings such as device network configuration, admin/API passwords/keys, upstream DNS resolvers, etc. It will also **not** keep DHCP settings or device leases synchronized. 

## Prerequisites
### System Requirements
Gravity Sync **requires** Pi-hole 5.0 or higher be already installed on your server.
- Gravity Sync is regularly tested during development with on any of the Linux distrobutions that Pi-hole is [certified to run on](https://docs.pi-hole.net/main/prerequesites/#supported-operating-systems). As Gravity Sync is just an (admittedly) long bash script, it will likely work on other Linux distributions that have the the necessary components.
- Gravity Sync uses the `SUDO` command to elevate permissions for itself, on both Pi-hole systems, during execution. You will need to make sure that you have passwordless SUDO enabled for the accounts on both the primary and secondary Pi-hole that will be performing the work. Most of the pre-built images available for the Raspberry Pi already have this configured, but if you have your Pi-hole running in a virtual machine built from a generic ISO, you may need to [adjust this manually](https://linuxize.com/post/how-to-run-sudo-command-without-password/).
- Gravity Sync has not been tested with Docker deployments of Pi-hole, and is not expected to work there without major modifications. You will need Pi-hole setup with a "traditional" install directly in the base operating system. There are likely other methods of sharing the `gravity.db` file between multiple Docker instances that are better suited to a container environment.
- Gravity Sync leverages SSH and RSYNC to do the leavy lifting between your Pi-hole nodes. OpenSSH is reccomended but if you're using a ultra-lightweight Pi distrbution (such as DietPi) that uses Dropbear by default, it should work as well. Other SSH client/server combonations are not supported at this time.

### Pi-hole Architecture
You will want to designate one Pi-Hole as primary and at least one as secondary. The primary Pi-hole is where you'll make most of your configuration changes through the Web UI, doing things such as; manual allow-listing, adding blocklists, device/group management, configuring custom/local network DNS, and other changing other list settings. The secondary Pi-hole(s) are where you will install and configure Gravity Sync.

The designation of primary and secondary is purely at your discretion. The doesn't matter if you're using an HA process like keepalived to present a single DNS IP address to clients, or handing out two DNS resolvers via DHCP. Generally it is expected that the two (or more) Pi-hole(s) will be at the same phyiscal location, or at least on the same internal networks. It should also be possible to to replicate to a secondary Pi-hole across networks, either over a VPN or open-Internet, with the approprate firewall/NAT configuration.

Starting with version 2.0, Gravity Sync will sync the `gravity.db` and `custom.list` files on each Pi-hole with each other. (Previous versions only pulled data one way.) 

## Installation
Login to your *secondary* Pi-hole, and run:

```bash
git clone https://github.com/vmstan/gravity-sync.git $HOME/gravity-sync
```

You will now have a folder called `gravity-sync` in your home directory. Everything Gravity Sync runs from there.

Proceed to the Configuration section.

## Configuration
After you install Gravity Sync to your server you will need to create a configuration file called `gravity-sync.conf` in the same folder as the script. 

```bash
./gravity-sync.sh config
```

This will guide you through the process of:
- Specifying the IP or DNS name of your primary Pi-hole
- Specifying the SSH username to connect to your primary Pi-hole
- Selecting the SSH authentication mechanism (key-pair or password)
- Configuring your key-pair and applying it to your primary Pi-hole
- Testing your authentication method

After you've completed your configuration, proceed to the Execution phase.

## Execution
Now, test Gravity Sync. You can run a comparison between primary and secondary databases, which will be non-distruptive, and see if everything has been configured correctly.

```bash
./gravity-sync.sh compare
```

Assuming Gravity Sync runs successfully, it will indicate if there are changes pending between the two databases. If not, make a subtle change to a whitelist/blacklist on your primary Pi-hole, such as changing a description field or disabling a whitelist item, and then running `./gravity-sync.sh compare` again to validate your installation is working correctly.

### Smart Sync

The default command for Gravity Sync is simple.

```
./gravity-sync.sh`
```

But you can also run `./gravity-sync.sh smart` if you feel like it, and it'll do the same thing.

It will perform some checks to help insure success and then stop before making changes if it detects an issue. It will also perform the same `compare` function outlined above, and if there are no changes pending, it will exit without making an attempt to copy data.

**Example:** If the `gravity.db` has been modified on the primary Pi-hole, but the `custom.list` file has been changed on the secondary, Gravity Sync will now do a pull of the `gravity.db` then push `custom.list` and finally restart the correct components on each server. It will also now only perform a sync of each component if there are changes within each type to replicate. So if you only make a small change to your Local DNS settings, it doesn't kickoff the larger `gravity.db` replication.

This allows you to be more flexible in where you make your configuration changes to block/allow lists and local DNS settings being made on either the primary or secondary, but it's best practice to continue making changes on one side where possible. In the event there are configuration changes to the same element (example, `custom.list` changes at both sides) then Gravity Sync will attempt to determine based on timestamps on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync does not merge the contents of the files when changes happen, it simply overwrites the entire content.

If the execution completes, you will now have overwritten your running `gravity.db` and `custom.list` on the secondary Pi-hole after creating a copy of the running files (with `.backup` appended) in the `backup` subfolder located with your script. Gravity Sync will also keep a copy of the last sync'd files from the primary (in the `backup` folder appended with `.pull` or `.push`) for future use. 

Finally, a file called `gravity-sync.log` will be created in the `gravity-sync` folder along side the script with the date the script was last executed appended to the bottom.

You can check for successful pull attempts by running: `./gravity-sync.sh logs`

### The Pull Function
The Gravity Sync Pull, prior to version 2.0, was the standard method of sync operation, and will not prompt for user input after execution. 

```bash
./gravity-sync.sh pull
```

If the execution completes, you will now have overwritten your running `gravity.db` and `custom.list` on the secondary Pi-hole after creating a copy of the running files (with `.backup` appended) in the `backup` subfolder located with your script. Gravity Sync will also keep a copy of the last sync'd files from the primary (in the `backup` folder appended with `.pull`) for future use. 

### The Push Function
Gravity Sync includes the ability to `push` from the secondary Pi-hole back to the primary. This would be useful in a situation where your primary Pi-hole is down for an extended period of time, and you have made list changes on the secondary Pi-hole that you want to force back to the primary, when it comes online.

```bash
./gravity-sync.sh push
```

Before executing, this will make a copy of the remote database under `backup/gravity.db.push` and `backup/custom.list.push` then sync the local configuration to the primary Pi-hole.

This function purposefuly asks for user interaction to avoid being accidentally automated.

- If your script prompts for a password on the remote system, make sure that your remote user account is setup not to require passwords in the sudoers file.

### The Restore Function
Gravity Sync can also `restore` the database on the secondary Pi-hole in the event you've overwritten it accidentally. This might happen in the above scenario where you've had your primary Pi-hole down for an extended period, made changes to the secondary, but perhaps didn't get a chance to perform a `push` of the changes back to the primary, before your automated sync ran.

```bash
./gravity-sync.sh restore
```

This will copy your last `gravity.db.backup` and  `custom.list.backup` to the running copy on the secondary Pi-hole.

This function purposefuly asks for user interaction to avoid being accidentally automated.

## Updates
If you'd like to know what version of the script you have running the built in version checker. It will notify you if there are updates available.

 ```
 ./gravity-sync.sh version
 ``` 

You can then run the built-in updater to get the latest version of all the files. Both the `version` and `update` commands reach out to GitHub, so outbound access to github.com is required.

```bash
./gravity-sync.sh update
```

Your copy of the `gravity-sync.conf` file, logs and backups should not be be impacted by this update, as they are specifically ignored. The main goal of Gravity Sync is to be simple to execute and maintain, so any additional requirements should also be called out when it's executed. After updating, be sure to manually run a `./gravity-sync.sh compare` or `./gravity-sync.sh pull` to validate things are still working as expected. 

You can run a `./gravity-sync.sh config` at any time to generate a new configuration file if you're concerned that you're missing something.

- If the update script fails, make sure you did your original deployment via `git clone` and not a manual install. Refer to [ADVANCED.md](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md) for more details.

## Automation
Automation of sync is accomplished by adding an execution of the script to the user's crontab file. As Gravity Sync won't make any changes if it doesn't detect a difference to sync, then the impact should be minor to your systems.

```bash
./gravity-sync.sh automate
```

Select the frequency per hour (in minutes) that you'd like to sync and that's it.

Now, make another small adjustment to your primary settings and wait until annointed time to see if your changes have been synchronized. If so, profit! If not, start from the beginning. From this point forward any blocklist changes you make to the primary will reflect on the secondary within the frequency you select.

If you'd like to see the log of what was run the last crontab, you can view that output by running:

```bash
./gravity-sync.sh cron
```

Keep in mind if your cron task has never run, you will not see any valid output from this command.

### Adjusting Automation
You can verify your existing automation entry by running `crontab -l` and see it listed at the bottom of the crontab file. If you decide to remove or change your frequency (as of version 1.8.3) you can run `./gravity-sync.sh automate` again and pick a new timing, including setting it to 0 to disable automation.

## Advanced Installation
Please review the [Advanced Installation](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md) guide for assistance.

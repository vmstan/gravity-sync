# Gravity Sync
## Features
What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking ads via DNS on your network? That's right, Two Pi-hole! (Redundency is key in any network infrastucture.) But if you have more than one Pi-hole in your network you'll want a simple way to keep the list configurations and local DNS settings identical between the two. That's where Gravity Sync comes in. 

Gravity Sync will:
- Sync the allow/blocklist configurations stored in `gravity.db` between two Pi-hole
- Sync the local DNS settings stored in `custom.list` between two Pi-hole. 
- Provide an easy way to keep this happening in the background. 

Ideally you set up Gravity Sync and forget about it -- and in the long term, it would be awesome if the Pi-hole team made this entire script unncessary.

### Limitations
Gravity Sync will **not**:
- Overwrite individual Pi-hole specific settings such as the device's network configuration, admin/API passwords/keys, upstream DNS resolvers, etc.
- Keep DHCP settings or device leases synchronized. 

It is suggested that you use an external DHCP server on your network (such as your router) when using multiple Pi-hole.

### Disclaimer
Gravity Sync is not developed by or affiliated with the Pi-hole project. This is a community effort that seeks to implement replication, which is currently not a part of the core Pi-hole product. The code has been well tested across multiple user environments but there always is an element of risk involved with running any arbitrary software you find on the Internet.

## Requirements
- Pi-hole 5.0 (or higher) be installed on at least two systems, using any of the Linux distros that Pi-hole is [certified to run on](https://docs.pi-hole.net/main/prerequesites/#supported-operating-systems). Docker deployments of Pi-hole are not supported.
- You will need to make sure that you have passwordless `SUDO` enabled for the accounts on both the primary and secondary Pi-hole that will be performing the work. Most of the pre-built images available for the Raspberry Pi already have this configured, but if you have your Pi-hole running in a virtual machine built from a generic ISO, you may need to [adjust this manually](https://linuxize.com/post/how-to-run-sudo-command-without-password/).
- Make sure `SSH` and `RSYNC` are installed on both the primary and secondary Pi-hole prior to installation. This is what does the leavy lifting between your Pi-hole nodes. OpenSSH is reccomended but if you're using a ultra-lightweight Pi distrbution (such as DietPi) that uses Dropbear by default, it should work as well. Other SSH client/server combonations are not supported at this time.

### Pi-hole Architecture
You will want to designate one Pi-Hole as primary and at least one as secondary. The primary Pi-hole is where you'll make most of your configuration changes through the Web UI, doing things such as; manual allow-listing, adding blocklists, device/group management, configuring custom/local network DNS, and other changing other list settings. The secondary Pi-hole(s) are where you will install and configure Gravity Sync.

For more information and for reference architectures, please [refer to this document](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md#reference-architectures)

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
- Specifying the IP or DNS name of your primary Pi-hole.
- Specifying the SSH username to connect to your primary Pi-hole.
- Selecting the SSH authentication mechanism (key-pair or password.)
- Configuring your key-pair and applying it to your primary Pi-hole.
- Testing your authentication method, and testing RSYNC to the primary.

After you've completed your configuration, proceed to the Execution phase.

## Execution
Now, test Gravity Sync. You can run a comparison between primary and secondary databases, which will be non-distruptive, and see if everything has been configured correctly.

```bash
./gravity-sync.sh compare
```

Assuming Gravity Sync runs successfully, it will indicate if there are changes pending between the two databases. If not, make a subtle change to a allowlist/blocklist on your primary Pi-hole, such as changing a description field or disabling a allowlist item, and then running `./gravity-sync.sh compare` again to validate your installation is working correctly.

### The Sync

The default command for Gravity Sync is simple.

```
./gravity-sync.sh
```

But you can also run `./gravity-sync.sh smart` if you feel like it, and it'll do the same thing.

Gravity Sync will perform some checks to help insure success and then stop before making changes if it detects an issue. It will also perform the same `compare` function outlined above, and if there are no changes pending, it will exit without making an attempt to copy data.

**Example:** If the `gravity.db` has been modified on the primary Pi-hole, but the `custom.list` file has been changed on the secondary, Gravity Sync will now do a pull of the `gravity.db` then push `custom.list` and finally restart the correct components on each server. It will also now only perform a sync of each component if there are changes within each type to replicate. So if you only make a small change to your Local DNS settings, it doesn't kickoff the larger `gravity.db` replication.

This allows you to be more flexible in where you make your configuration changes to block/allow lists and local DNS settings being made on either the primary or secondary, but it's best practice to continue making changes on one side where possible. In the event there are configuration changes to the same element (example, `custom.list` changes at both sides) then Gravity Sync will attempt to determine based on timestamps on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync does not merge the contents of the files when changes happen, it simply overwrites the entire content.

If the execution completes, you will now have overwritten your running `gravity.db` and `custom.list` on the secondary Pi-hole after creating a copy of the running files (with `.backup` appended) in the `backup` subfolder located with your script. Gravity Sync will also keep a copy of the last sync'd files from the primary (in the `backup` folder appended with `.pull` or `.push`) for future use. 

Finally, a file called `gravity-sync.log` will be created in the `gravity-sync` folder along side the script with the date the script was last executed appended to the bottom.

You can check for successful pull attempts by running: `./gravity-sync.sh logs`

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
Please review the [Advanced Installation](https://github.com/vmstan/gravity-sync/blob/master/ADVANCED.md) guide for more assistance.

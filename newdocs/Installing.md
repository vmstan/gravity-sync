Please make sure you've read over the [System Requirements](https://github.com/vmstan/gravity-sync/wiki/System-Requirements) prior to beginning your installation. 


### Installation Script

Open an SSH session to each Pi-hole, and execute the following script.

```bash
curl -sSL https://gravity.vmstan.com | bash
```

The installer will validate that you have all the necessary components to use Gravity Sync, including an active Pi-hole deployment. It will also add a passwordless sudo configuration file for the current user, if it is required.

Make sure you have run the installation script on both Pi-hole before starting the configuration.

# Configuration

 If you do not have an existing configuration file, the installer will prompt to create one. It can also be run later by executing `gravity-sync config`. Each Gravity Sync install requires it's own unique configuration.

The configuration utility will guide you through the process of:

- Specifying the IP address of the remote Pi-hole instance.
- Specifying the SSH username to connect to your remote Pi-hole host.
- Creating a unique keyfile and pairing it to your remote Pi-hole.
- Providing details about how each of your two Pi-hole are configured.

The configuration will be saved as `gravity-sync.conf` in the same folder as the script. If you need to make adjustments to your settings in the future, you can edit this file or run the configuration tool to generate a new one.

If you are deploying Gravity Sync to a system using Docker containers, Gravity Sync should detect this and prompt for additional configuration.

After you're pleased with your configuration, proceed to the Execution phase.

## Execution

Now, test Gravity Sync. You can run a comparison between primary and secondary databases, which will be non-disruptive, and see if everything has been configured correctly.

```bash
./gravity-sync.sh compare
```

Assuming Gravity Sync runs successfully, it will indicate if there are changes pending between the two databases. 

**Important!** If you have just performed a fresh install of your secondary Pi-hole (where Gravity Sync is now installed) and it's list configurations do not already match your primary, run `./gravity-sync.sh pull` to bring all of the settings from the primary over to the secondary. You should do this before you run a standard sync, as it may see the default secondary Pi-hole configuration as newer and overwrite them on the primary.

### The Sync

The default command for Gravity Sync is simple.

```bash
./gravity-sync.sh
```

But you can also run `./gravity-sync.sh smart` if you feel like it, and it'll do the same thing.

Gravity Sync will perform some checks to help ensure success and then stop before making changes if it detects an issue. It will also perform the same `compare` function outlined above, and if there are no changes pending, it will exit without making an attempt to copy data.

**Example:** If the `gravity.db` has been modified on the primary Pi-hole, but the `custom.list` file has been changed on the secondary, Gravity Sync will now do a pull of the `gravity.db` then push `custom.list` and finally restart the correct components on each server. It will also now only perform a sync of each component if there are changes within each type to replicate. So if you only make a small change to your Local DNS settings, it doesn't kickoff the larger `gravity.db` replication.

This allows you to be more flexible in where you make your configuration changes to block/allow lists and local DNS settings being made on either the primary or secondary, but it's best practice to continue making changes on one side where possible. In the event there are configuration changes to the same element (example, `custom.list` changes at both sides) then Gravity Sync will attempt to determine based on timestamps on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync does not merge the contents of the files when changes happen, it simply overwrites the entire content.

If the execution completes, you will now have a synchronized copy of your running `gravity.db`, `custom.list` and `05-pihole-custom-cname.conf` on the both Pi-hole after creating a time-stamped copy of the running files (with `.backup` appended) in the `backup` subfolder located with your script, on the secondary Pi-hole.

Finally, a file called `gravity-sync.log` will be created in the `gravity-sync` folder along side the script with the date the script was last executed appended to the bottom.

You can check for successful pull attempts by running: `./gravity-sync.sh logs`

## Automation

Automation of sync is accomplished by adding an execution of the script to host's systemd configuration. As Gravity Sync won't make any changes if it doesn't detect a difference to sync, then the impact should be minor to your systems.

```bash
./gravity-sync.sh automate
```

Automation tasks within systemd are configured by default to run every 5-10 minutes after being started. (This is 5 minutes + a random timer < 5 minutes.) Replications will automatically attempt for the first time 2 minutes after the system is powered on.

Now, make another small adjustment to your primary settings and wait until anointed time to see if your changes have been synchronized. If so, profit! If not, start from the beginning. From this point forward any block list changes you make to the primary will reflect on the secondary within the frequency you select.
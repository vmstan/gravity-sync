# Installing

## Gravity Sync 4

Please make sure you've read over the [System Requirements](https://github.com/vmstan/gravity-sync/wiki/System-Requirements) prior to beginning your installation.

### Installation Script

Open an SSH session to each Pi-hole, and execute the following script.

```bash
curl -sSL https://gravity.vmstan.com | bash
```

The installer will validate that you have all the necessary components to use Gravity Sync, including an active Pi-hole deployment. It will also add a password-less sudo configuration file for the current user, if it is required.

Make sure you have run the installation script on both Pi-hole before starting the configuration.

# Configuration

 If you do not have an existing configuration file, the installer will prompt to create one. It can also be run later by executing `gravity-sync config`. Each Gravity Sync install requires it's own unique configuration.

The configuration utility will guide you through the process of:

- Specifying the IP address of the remote Pi-hole instance.
- Specifying the SSH username to connect to your remote Pi-hole host.
- Creating a unique key and pairing it to your remote Pi-hole.
- Providing details about how each of your two Pi-hole are configured.

The configuration will be saved as `gravity-sync.conf` in `/etc/gravity-sync`. If you need to make adjustments to your settings in the future, you can edit this file or run the configuration tool to generate a new one.

After you're pleased with your configuration of both Gravity Sync instances, proceed to the Execution phase.

## Execution

Now, test Gravity Sync. You can run a comparison between remote and local databases, which will be non-disruptive, and see if everything has been configured correctly.

```bash
./gravity-sync.sh compare
```

Assuming Gravity Sync runs successfully, it will indicate if there are changes pending between the two databases.

You must now pick the Pi-hole instance that currently has the "authoritative" list of settings and run the following command to send all of those settings to its peer for the first time.

```bash
gravity-sync push
```

If you do not follow this step, especially if one of your Pi-hole instances is a fresh install, you run the risk of overwriting your current configuration with a default setup or something else less desireable.

### The Sync

The default command for Gravity Sync is simple.

```bash
./gravity-sync.sh
```

Gravity Sync will perform some checks to help ensure success and then stop before making changes if it detects an issue. It will also perform the same `compare` function outlined above, and if there are no changes pending, it will exit without making an attempt to copy data.

**Example:** If the `gravity.db` has been modified on the remote Pi-hole, but the `custom.list` file has been changed on the local, Gravity Sync will now do a pull of the `gravity.db` then push `custom.list` and finally restart the correct components on each server. It will also only perform a sync of each component if there are changes within each type to replicate. So if you only make a small change to your Local DNS settings, it doesn't kickoff the larger `gravity.db` replication.

In the event there are configuration changes to the same element (example, `custom.list` changes at both sides) then Gravity Sync will attempt to determine based on timestamps on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync **does not** merge the contents of the files.

If the execution completes, you will now have a synchronized copy of your running `gravity.db`, `custom.list` and `05-pihole-custom-cname.conf` on both Pi-hole.

## Automation

Automation of sync is accomplished by adding an execution of the script to each host's systemd configuration.

```bash
./gravity-sync.sh auto
```

Automation tasks within systemd are configured by default to run every 5-10 minutes after being started. (This is 5 minutes + a random timer < 5 minutes.) Replications will automatically attempt for the first time 2 minutes after the system is powered on.

Now, make another small adjustment to your primary settings and wait until anointed time to see if your changes have been synchronized. If so, profit! If not, start from the beginning. From this point forward any block list changes you make to the primary will reflect on the secondary within the frequency you select.

# Gravity Sync

For more information visit [https://vmstan.com/gravity-sync/](https://vmstan.com/gravity-sync/)

## Background

If you have more than one Pi-hole (PH) in your network and you want to keep the list configurations identical between the two, you've come to the right place.

The script assumes you have one "primary" PH as the place you make all your configuration changes through the Web UI, doing things such as; manual whitelisting, adding blocklists, device/group management, and other list settings. The script will pull the configuration of the primary PH to the secondary. 

It will **not** overwrite device specific settings such as local network configuration, admin/API passwords/keys, upstream DNS resolvers, etc. It will also **not** keep DHCP settings or device leases synchronized. 

## Prereqs

You will need to designate one Pi-Hole as primary and one as secondary. The designation is purely at your discretion and depends on your desired use case:

- If you have multiple PH instances advertised to your users via DHCP, you will need to pick one to consistently use for changes and put this script on the other one(s).
- If you have both running in an active/passive HA configuration using keepslived, as I do, then you will likely make all your changes to the active member of the pair. In this case the script runs from the passive node.

Additionally, some things to consider:

- This script was designed to work with the inital release of Pi-Hole 5.0 but should work with any future versions that have a gravity.db file holding the configurations.
- This script will not work on any version of Pi-Hole prior to version 5.0, as it uses a different list format.
- This script has been tested with Ubuntu  and Rasbian, both based on Debian Linux. It will likely work on other distros but they have not been tested.
- This script has not been tested with Docker container deployments of Pi-hole. I do not suspect it will work without major modifications. You will need Pi-hole setup with a "traditional" install directly in the base operating system.
- This script has been tested between two Raspberry Pi 4 devices, but should work fine between any two PH instances that meet the above requirements. (Such as VM > VM, or VM > Pi, etc.)
- While not strictly a requirement, for the purposes of running a multi-PH network, I suggest using your router's DHCP function (or another DHCP server) to hand out PH DNS settings to clients. I have not tested this script on networks using the PH DHCP function, however as outlined above it will not have any direct impact to the functionality.

### SSH Keypairs

You'll need to generate an SSH key for your secondary PH user and copy it to your primary PH. This will allow you to connect to and copy the gravity.db file without needing a password each time.

*Note: If you already have this setup on your systems for other purposes, you can skip this step.*

```
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub USERNAME@PRIMARYPI
```

Subsitute USERNAME for the account on the primary PH with sudo permissions, and PRIMARYPI for the IP or DNS name of the PH you have designated as the primary. 

## Installation

The main purpose of this script is my own personal use, but if you find it helpful then I encourage you to use it and if you'd like provide feedback or contribute. As such, I'll lay out two ways to consume it. The first is more bleeding edge in that you'll download and run whatever the latest version of the script is on GitHub.

If this is too aggressive for you, you want to make changes to the script specific to your environment and not contribute those changes back, or your worried it'll blow something up, then please proceed to option 2.

### Option 1

Login to your *secondary* PH, and while in your users home directory, use `git` to clone the script to your server and keep the latest copy of the script on your server.

```
cd ~
git clone https://github.com/vmstan/gravity-sync.git
cd gravity-sync
```

Proceed to the Configuration section.

### Option 2

So a life on the wildside of file sync isn't for you? That's fine.

Download the latest release from [GitHub](https://github.com/vmstan/gravity-sync/releases) and extract the files to your *secondary* PH server.


```
cd ~
wget https://github.com/vmstan/gravity-sync/archive/v1.1.4.zip
unzip v1.1.4.zip
mv ~/gravity-sync-1.1.4 ~/gravity-sync
cd gravity-sync
```

Please note the script **must** be run from a folder in your user home directory (ex: /home/USER/gravity-sync) -- I wouldn't suggest deviating from the gravity-sync folder name. If you do you'll need to also change the configuration settings defined in the `gravity-sync.sh` script, which can be a little tedious to do everytime you upgrade the script.

## Configuration

After you clone the base configuration, you will need to create a configuration file called `gravity-sync.conf` in the same folder as the script. There will be a file called `gravity-sync.conf.example` that you can use as the basis for your file. 

Make a copy of the example file and modify it with your site specific settings.

```
cp gravity-sync.conf.example gravity-sync.conf
vim gravity-sync.conf
```

*Note: If you don't have VIM on your system use VI, if you don't like VI use NANO, or if you don't like any of those subsitute for your text editor of choice. I'm not here to start a war.*

Make sure you've set the REMOTE_HOST and REMOTE_USER variables with the IP (or DNS name) and user account to authenticate to the primary Pi. This account will need to have sudo permissions on the remote system.

```
REMOTE_HOST='192.168.1.10'
REMOTE_USER='pi'
```

Save. Keep calm, carry on.

## Execution

Now test the script. I suggest making a subtle change to a whitelist/blacklist on your primary PH, such as a description field, and then seeing if the change propagates to your secondary.

The script, when functioning in `pull` mode, will not prompt for user input after execution. It will perform some checks to help insure success and then stop before making changes if it detects an issue.

```
./gravity-sync.sh pull
```

If the execution completes, you will now have overwritten your running gravity.db on the secondary PH after creating a copy (`gravity.db.backup`) in the `/etc/pihole` directory. The script will also keep a copy of the last sync'd gravity.db from the master, in the `gravity-sync` folder (`gravity.db.last`) should you need it. 

Finally, a file called `gravity-sync.log` will be created in the `gravity-sync` folder along side the script, with the date the script was last executed appended to the bottom. Over time I intend for this logging function to become more helpful.

## Failover

There is an option in the script to `push` from the secondary PH back to the primary. This would be useful in a situation where your primary PH is down for an extended period of time, and you have made list changes on the secondary PH that you want to force back to the primary, when it comes online.

```
./gravity-sync.sh push
```

Please note that the "push" option *does not make any backups of anything*. There is a warning about potental data loss before executing this function. This function purposefuly asks for user interaction to avoid being accidentally automated.

## Updates

If you installed via Option 1, you can run the built-in updater to get the latest version of all the files.

```
./gravity-sync.sh update
```

Your changes to the .conf file, logs and gravity.db backups should not be be impacted by this update, as they are specifically ignored by git.

If you installed via Option 2, download and overwrite the `gravity-sync.sh` file with a newer version.

With either version, you should review the contents of the example configuration file to make sure there are no new required settings.

## Automation

I've automated my synchronization using Crontab. If you'd like to keep this a manual process then ignore this section. By default my script will run at the top and bottom of every hour (1:00 PM, 1:30 PM, 2:00 PM, etc) but you are free to dial this back if you feel this is too aggressive by adjusting your cron timer.

```
crontab -e
*/30 * * * * /home/USER/gravity-sync/gravity-sync.sh pull >/dev/null 2>&1
```

Now, make another small adjustment to your primary settings. Now just wait until the annointed hour, and see if your changes have been synchronized. If so, profit!

If not, start from the beginning.

From this point forward any blocklist changes you make to the primary will reflect on the secondary within 30 minutes.

## Troubleshooting

If you are unable to run the `gravity-sync.sh` file, make sure it's marked as an executable by Linux.

```
chmod +x gravity-sync.sh
```

If you'd like to know what version of the script you have running.

```
./gravity-sync.sh version
```

If the update script fails, make sure you did your original deployment via `git clone` and not a manual install. If it doesn't kick off, you can manually execute a `git pull` while in the `gravity-sync` directory. 

For additional Git issues, get in line.
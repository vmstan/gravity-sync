# Gravity Sync

## Background

What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking ads via DNS on your network? That's right, Two Pi-hole! But if you have more than one Pi-hole (PH) in your network you'll want a simple way to keep the list configurations identical between the two.

That's Gravity Sync.

![Pull execution](https://user-images.githubusercontent.com/3002053/82774990-f88c6200-9e0b-11ea-97e5-23c8b38f32e3.png)

Gravity Sync will **not** overwrite device specific settings such as local network configuration, admin/API passwords/keys, upstream DNS resolvers, etc. It will also **not** keep DHCP settings or device leases synchronized. 

## Prerequisites

Gravity Sync **requires** Pi-hole 5.0 or higher.

You will need to designate one Pi-Hole as primary and one as secondary. This is where you'll make all your configuration changes through the Web UI, doing things such as; manual whitelisting, adding blocklists, device/group management, and other list settings. Gravity Sync will pull the configuration of the primary PH to the secondary. It will also bring over the downloaded blocklist files after a `pihole -g` update on the primary, so you do not need to reach out to all your blocklist hosts for updates after syncing.

The designation of primary and secondary is purely at your discretion and depends on your desired use case.

Additionally, some things to consider:

- Gravity Sync has been tested with Ubuntu and Rasbian. It will likely work on other distros but they have not been tested. Please let me know if you have any issues.
- Gravity Sync has not been tested with Docker container deployments of Pi-hole, and is not expected to work there without major modifications. You will need Pi-hole setup with a "traditional" install directly in the base operating system.

## Installation

The main purpose of this script is my own personal use, but if you find it helpful then I encourage you to use it and if you'd like provide feedback or contribute. As such, I'll lay out two ways to consume it. The first is more bleeding edge in that you'll download and run whatever the latest version of the script is on GitHub.

If this is too aggressive for you, maybe because you want to make changes to the script that are specific to your environment, or you're worried it'll blow something up, then please proceed to option 2.

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
wget https://github.com/vmstan/gravity-sync/archive/v1.3.1.zip
unzip v1.3.1.zip
mv ~/gravity-sync-1.3.1 ~/gravity-sync
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

Do not set the `REMOTE_PASS` variable until you've read the next section on SSH.

### SSH Configuration

Gravity Sync uses SSH to run commands on the primary Pi-hole, and sync the two systems by performing file copies. There are two methods available for authenticating with SSH.

#### Key-Pair Authentication

This is the preferred option, as it's more reliable and less dependant on third party plugins.

You'll need to generate an SSH key for your secondary PH user and copy it to your primary PH. This will allow you to connect to and copy the gravity.db file without needing a password each time. When generating the SSH key, accept all the defaults and do not put a passphrase on your key file.

*Note: If you already have this setup on your systems for other purposes, you can skip this step.*

```
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub REMOTE_USER@REMOTE_HOST
```

Subsitute REMOTE_USER for the account on the primary PH with sudo permissions, and REMOTE_HOST for the IP or DNS name of the PH you have designated as the primary. 

Make sure to leave the `REMOTE_PASS` variable set to nothing in `gravity-sync.conf` if you want to use key-pair authentication.

#### Password Authentication

This is the non-preferred option, as it depends on an non-standard utility called `sshpass` which must be installed on your secondary PH. Install it using your package manage or choice. The example below is for Raspbian or Ubuntu.

```
sudo apt install sshpass
```

Then enter your password in the `gravity-sync.conf` file you configured above.

```
REMOTE_PASS='password'
```

Gravity Sync will validate that the `sshpass` utility is installed on your system and failback to attempting key-pair authentication if it's not detected.

Save. Keep calm, carry on.

## Execution

Now test the script. You can run a comparison between the two which will be non-distruptive and see if everything has been configured correctly.

```
./gravity-sync.sh compare
```

Assuming Gravity Sync runs successfully, it'll indicate if there are changes pending between the two databases. If not, I suggest making a subtle change to a whitelist/blacklist on your primary PH, such as a description field, and then running it again to validate your installation is working correctly.

Gravity Sync, when functioning in `pull` mode, will not prompt for user input after execution. It will perform some checks to help insure success and then stop before making changes if it detects an issue. If there are no changes pending, it will exit without making an attempt to copy data.

```
./gravity-sync.sh pull
```

If the execution completes, you will now have overwritten your running gravity.db on the secondary PH after creating a copy of the running database (`gravity.db.backup`) in the `backup` subfolder located with your script. The script will also keep a copy of the last sync'd gravity.db from the master, in the `backup` folder identified as `gravity.db.pull` should you need it for some reason. 

Finally, a file called `gravity-sync.log` will be created in the `gravity-sync` folder along side the script, with the date the script was last executed appended to the bottom.

You can check for successful pull attempts by running: `./gravity-sync.sh logs`

## Failover

Gravity Sync includes the ability to `push` from the secondary PH back to the primary. This would be useful in a situation where your primary PH is down for an extended period of time, and you have made list changes on the secondary PH that you want to force back to the primary, when it comes online.

```
./gravity-sync.sh push
```

Before executing, this will make a copy of the remote database under `backup/gravity.db.push` then sync the local configuration to the primary PH.

This function purposefuly asks for user interaction to avoid being accidentally automated.

## Updates

If you installed via Option 1, you can run the built-in updater to get the latest version of all the files.

```
./gravity-sync.sh update
```

Your copy of the `gravity-sync.conf` file, logs and backups should not be be impacted by this update, as they are specifically ignored by git.

If you installed via Option 2, download and overwrite the `gravity-sync.sh` file with a newer version. With either version, you should review the contents of the script bundle, specifically the example configuration file, to make sure there are no new required settings. 

The goal of Gravity Sync is to be simple, so any additional requirements should also be called out when it's executed. After updating, be sure to manually run a `./gravity-sync.sh compare` or `./gravity-sync.sh pull` to validate things are still working as expected.

## Automation

I've automated my synchronization using Crontab. If you'd like to keep this a manual process then ignore this section. By default my script will run at the top and bottom of every hour (1:00 PM, 1:30 PM, 2:00 PM, etc) but you are free to dial this back if you feel this is too aggressive by adjusting your cron timer.

As Gravity Sync won't make any changes if it doesn't detect a difference to sync, then it's impact should be minor to your systems.

```
crontab -e
*/30 * * * * /bin/bash /home/USER/gravity-sync/gravity-sync.sh pull > /home/USER/gravity-sync/gravity-sync.cron
```

Now, make another small adjustment to your primary settings. Now just wait until the annointed hour, and see if your changes have been synchronized. If so, profit!

If not, start from the beginning.

From this point forward any blocklist changes you make to the primary will reflect on the secondary within 30 minutes.

If you'd like to see the log of what was run the last crontab, you can view that output.

```
./gravity-sync.sh cron
```

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

If your script prompts for a password on the remote system, make sure that your user account is setup not to require passwords in the sudoers file.

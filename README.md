# Gravity Sync
## Background
What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking ads via DNS on your network? That's right, Two Pi-hole! But if you have more than one Pi-hole (PH) in your network you'll want a simple way to keep the list configurations identical between the two.

That's Gravity Sync.

![Pull execution](https://user-images.githubusercontent.com/3002053/82915078-e870a180-9f35-11ea-8b36-271a02acdeaa.gif)

Gravity Sync will **not** overwrite device specific settings such as local network configuration, admin/API passwords/keys, local hostfiles, upstream DNS resolvers, etc. It will also **not** keep DHCP settings or device leases synchronized. 

## Prerequisites
Gravity Sync **requires** Pi-hole 5.0 or higher.

You will need to designate one Pi-Hole as primary and one as secondary. This is where you'll make all your configuration changes through the Web UI, doing things such as; manual whitelisting, adding blocklists, device/group management, and other list settings. Gravity Sync will pull the configuration of the primary PH to the secondary. It will also bring over the downloaded blocklist files after a `pihole -g` update on the primary, so you do not need to reach out to all your blocklist hosts for updates after syncing.

The designation of primary and secondary is purely at your discretion and depends on your desired use case.

Additionally, some things to consider:

- Gravity Sync is regularly tested during development with Ubuntu and Raspberry Pi OS (previously, Raspbian). As Gravity Sync is just an (admittedly) long bash script, it will likely work on other Linux distributions that have the `bash` shell installed. But please file an Issue if you're unable to run it on another platform.
- Gravity Sync has not been tested with Docker container deployments of Pi-hole, and is not expected to work there without major modifications. You will need Pi-hole setup with a "traditional" install directly in the base operating system.

## Installation
### The Easy Way

Login to your *secondary* Pi-hole, and run:

```bash
git clone https://github.com/vmstan/gravity-sync.git $HOME/gravity-sync
```

You will now have a folder called `gravity-sync` in your home directory. Everything Gravity Sync runs from there.

Proceed to the Configuration section.

### The Less Easy Way
Don't trust `git` to install your software, or just like doing things by hand? That's fine. 

*Keep in mind that installing via this method means you won't be able to use Gravity Sync's built-in update mechanism.*

Download the latest release from [GitHub](https://github.com/vmstan/gravity-sync/releases) and extract the files to your *secondary* Pi-hole server.

```bash
cd ~
wget https://github.com/vmstan/gravity-sync/archive/v1.5.0zip
unzip v1.5.0.zip
mv ~/gravity-sync-1.5.0 ~/gravity-sync
cd gravity-sync
```

Please note the script **must** be run from a folder in your user home directory (ex: /home/USER/gravity-sync) -- I wouldn't suggest deviating from the gravity-sync folder name. If you do you'll need to also change the configuration settings defined in the `gravity-sync.sh` script, which can be a little tedious to do everytime you upgrade the script.

## Configuration
After you install Gravity Sync to your server (reguardless of the option you selected above) you will need to create a configuration file called `gravity-sync.conf` in the same folder as the script. 

### The Easy Way

```bash
./gravity-sync config
```

This will guide you through the process of:
- Specifying the IP or DNS name of your primary Pi-hole
- Specifying the SSH username to connect to your primary Pi-hole
- Selecting the SSH authentication mechanism (key-pair or password)
- Configuring your key-pair and applying it to your primary Pi-hole
- Testing your authentication method

After you've completed your configuration, proceed to the Execution phase.

### The Less Easy Way
There will be a file called `gravity-sync.conf.example` that you can use as the basis for your own `gravity-sync.conf` file. Make a copy of the example file and modify it with your site specific settings.

```bash
cp gravity-sync.conf.example gravity-sync.conf
vi gravity-sync.conf
```

*Note: If you don't like VI or don't have VIM on your system, use NANO, or if you don't like any of those subsitute for your text editor of choice. I'm not here to start a war.*

Make sure you've set the REMOTE_HOST and REMOTE_USER variables with the IP (or DNS name) and user account to authenticate to the primary Pi. This account will need to have sudo permissions on the remote system.

```bash
REMOTE_HOST='192.168.1.10'
REMOTE_USER='pi'
```

*Do not set the `REMOTE_PASS` variable until you've read the next section on SSH.*

### SSH Configuration
Gravity Sync uses SSH to run commands on the primary Pi-hole, and sync the two systems by performing file copies. There are two methods available for authenticating with SSH.

#### Key-Pair Authentication
This is the preferred option, as it's more reliable and less dependant on third party plugins.

You'll need to generate an SSH key for your secondary PH user and copy it to your primary PH. This will allow you to connect to and copy the gravity.db file without needing a password each time. When generating the SSH key, accept all the defaults and do not put a passphrase on your key file.

*Note: If you already have this setup on your systems for other purposes, you can skip this step.*

```bash
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub REMOTE_USER@REMOTE_HOST
```

Subsitute REMOTE_USER for the account on the primary PH with sudo permissions, and REMOTE_HOST for the IP or DNS name of the PH you have designated as the primary. 

Make sure to leave the `REMOTE_PASS` variable set to nothing in `gravity-sync.conf` if you want to use key-pair authentication.

#### Password Authentication
This is the non-preferred option, as it depends on an non-standard utility called `sshpass` which must be installed on your secondary PH. Install it using your package manager of choice. The example below is for Raspberry Pi OS (previously Raspbian) or Ubuntu.

```bash
sudo apt install sshpass
```

Then enter your password in the `gravity-sync.conf` file you configured above.

```bash
REMOTE_PASS='password'
```

Gravity Sync will validate that the `sshpass` utility is installed on your system and failback to attempting key-pair authentication if it's not detected.

Save. Keep calm, carry on.

## Execution
Now test the script. You can run a comparison between the two which will be non-distruptive and see if everything has been configured correctly.

```bash
./gravity-sync.sh compare
```

Assuming Gravity Sync runs successfully, it'll indicate if there are changes pending between the two databases. If not, I suggest making a subtle change to a whitelist/blacklist on your primary PH, such as changing a description field or disabling a whitelist item, and then running `./gravity-sync.sh compare` again to validate your installation is working correctly.

### The Pull Function

The Gravity Sync Pull, is the standard method of sync operation, and will not prompt for user input after execution. It will perform some checks to help insure success and then stop before making changes if it detects an issue. It will also perform the same `compare` function outlined above, and if there are no changes pending, it will exit without making an attempt to copy data.

```bash
./gravity-sync.sh pull
```

If the execution completes, you will now have overwritten your running gravity.db on the secondary PH after creating a copy of the running database (`gravity.db.backup`) in the `backup` subfolder located with your script. Gravity Sync will also keep a copy of the last sync'd gravity.db from the master, in the `backup` folder identified as `gravity.db.pull` for future use. 

Finally, a file called `gravity-sync.log` will be created in the `gravity-sync` folder along side the script with the date the script was last executed appended to the bottom.

You can check for successful pull attempts by running: `./gravity-sync.sh logs`

### The Push Function
Gravity Sync includes the ability to `push` from the secondary PH back to the primary. This would be useful in a situation where your primary PH is down for an extended period of time, and you have made list changes on the secondary PH that you want to force back to the primary, when it comes online.

```bash
./gravity-sync.sh push
```

Before executing, this will make a copy of the remote database under `backup/gravity.db.push` then sync the local configuration to the primary PH.

This function purposefuly asks for user interaction to avoid being accidentally automated.

## Updates
### The Easy Way
If you installed via **The Easy Way**, you can run the built-in updater to get the latest version of all the files.

```bash
./gravity-sync.sh update
```

Your copy of the `gravity-sync.conf` file, logs and backups should not be be impacted by this update, as they are specifically ignored.

### The Less Easy Way

You will need to download and overwrite the `gravity-sync.sh` file with a newer version. If you've chosen this path, I won't lay out exactly what you'll need to do every time, but you should at least review the contents of the script bundle (specifically the example configuration file) to make sure there are no new additional files or required settings. 

### Either Way
The main goal of Gravity Sync is to be simple to execute and maintain, so any additional requirements should also be called out when it's executed. After updating, be sure to manually run a `./gravity-sync.sh compare` or `./gravity-sync.sh pull` to validate things are still working as expected. 

You can run a `./gravity-sync.sh config` at any time to generate a new configuration file if you're concerned that you're missing something.

## Automation
Automation of sync is accomplished by adding an execution of the script to the user's crontab file. As Gravity Sync won't make any changes if it doesn't detect a difference to sync, then the impact should be minor to your systems.

### The Easy Way
Just run the built in `automate` function:

```bash
./gravity-sync.sh automate
```

Select the frequency per hour that you'd like to sync (once, twice, quadrice, etc) and that's it.

### The Less Easy Way
If you prefer to still use cron but modify your settings by hand, using the entry below will cause the entry to run at the top and bottom of every hour (1:00 PM, 1:30 PM, 2:00 PM, etc) but you are free to dial this back or be more agressive if you feel the need.

```bash
crontab -e
*/30 * * * * /bin/bash /home/USER/gravity-sync/gravity-sync.sh pull > /home/USER/gravity-sync/gravity-sync.cron
```

### Either Way
You can verify your cron entry by running `crontab -l` and see it listed at the bottom of the file. If you used the built in automation function and decide to change your frequency, you'll need to run `crontab -e` and adjust this by hand, or delete the entire line in the crontab file and then re-run the `./gravity-sync automate` function.

Now, make another small adjustment to your primary settings and wait until annointed time to see if your changes have been synchronized. If so, profit! If not, start from the beginning.

From this point forward any blocklist changes you make to the primary will reflect on the secondary within the frequency you select.

If you'd like to see the log of what was run the last crontab, you can view that output by running:

```bash
./gravity-sync.sh cron
```

## Troubleshooting
If you are just straight up unable to run the `gravity-sync.sh` file, make sure it's marked as an executable by Linux.

```bash
chmod +x gravity-sync.sh
```

- If your script prompts for a password on the remote system, make sure that your user account is setup not to require passwords in the sudoers file.
- If you use a non-standard SSH port to connect to your primary Pi-hole, you can add `SSH_PORT='123'` to the bottom of your `gravity-sync.conf` file. (Subsitute 123 for your non-standard port.) This will overwrite the `SSH_PORT=22` at the top of the script as it is imported later in the execution. 
- If you'd like to know what version of the script you have running by running `./gravity-sync.sh version` 
- If the update script fails, make sure you did your original deployment via `git clone` and not a manual install. 
- If it doesn't kick off, you can manually execute a `git pull` while in the `gravity-sync` directory. 
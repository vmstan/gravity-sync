# Gravity Sync
## Advanced Configuration
The purpose of this guide is to break out the manual install instructions, and any advanced configuration flags, into a seperate document to limit confusion from the primary README. It is expected that users have read and are familiar with the process and concepts outlined in the primary README.

## Prerequisites
- If you're installing Gravity Sync on a system running Fedora or CentOS, make sure that you are not just using the built in root account and have a dedicated user in the Administrator group. You'll also need SELinux disabled to install Pi-hole.

## Installation
If you don't trust `git` to install your software, or just like doing things by hand, that's fine. 

*Keep in mind that installing via this method means you won't be able to use Gravity Sync's built-in update mechanism.*

Download the latest release from [GitHub](https://github.com/vmstan/gravity-sync/releases) and extract the files to your *secondary* Pi-hole server.

```bash
cd ~
wget https://github.com/vmstan/gravity-sync/archive/v1.7.6.zip
unzip v1.7.6.zip -d gravity-sync
cd gravity-sync
```

Please note the script **must** be run from a folder in your user home directory (ex: /home/USER/gravity-sync) -- I wouldn't suggest deviating from the gravity-sync folder name. If you do you'll need to also change the configuration settings defined in the `gravity-sync.sh` script, which can be a little tedious to do everytime you upgrade the script.

## Configuration
After you install Gravity Sync to your server there will be a file called `gravity-sync.conf.example` that you can use as the basis for your own `gravity-sync.conf` file. Make a copy of the example file and modify it with your site specific settings.

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

You'll need to generate an SSH key for your secondary Pi-hole user and copy it to your primary Pi-hole. This will allow you to connect to and copy the necessary files without needing a password each time. When generating the SSH key, accept all the defaults and do not put a passphrase on your key file.

*Note: If you already have this setup on your systems for other purposes, you can skip this step.*

```bash
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub REMOTE_USER@REMOTE_HOST
```

Subsitute REMOTE_USER for the account on the primary Pi-hole with sudo permissions, and REMOTE_HOST for the IP or DNS name of the Pi-hole you have designated as the primary. 

Make sure to leave the `REMOTE_PASS` variable set to nothing in `gravity-sync.conf` if you want to use key-pair authentication.

#### Password Authentication
This is the non-preferred option, as it depends on an non-standard utility called `sshpass` which must be installed on your secondary Pi-hole. Install it using your package manager of choice. The example below is for Raspberry Pi OS (previously Raspbian) or Ubuntu.

```bash
sudo apt install sshpass
```

Then enter your password in the `gravity-sync.conf` file you configured above.

```bash
REMOTE_PASS='password'
```

Gravity Sync will validate that the `sshpass` utility is installed on your system and failback to attempting key-pair authentication if it's not detected.

Save. Keep calm, carry on.

### Hidden Figures
There are a series of advanced configuration options that you may need to change to better adapt Gravity Sync to your environment. They are referenced at the end of the `gravity-sync.conf` file. It is suggested that you make any necessary variable changes to this file, as they will superceed the ones located in the core script. If you want to revert back to the Gravity Sync default for any of these settings, just apply a `#` to the beginning of the line to comment it out.

#### `SSH_PORT=''`
Gravity Sync is configured by default to use the standard SSH port (22) but if you need to change this, such as if you're traversing a NAT/firewall for a multi-site deployment, to use a non-standard port.

Default setting in Gravity Sync is 22.

#### `SSH_PKIF=''`
Gravity Sync is configured by default to use the `.ssh/id_rsa` keyfile that is generated using the `ssh-keygen` command. If you have an existing keyfile stored somewhere else that you'd like to use, you can configure that here. The keyfile will still need to be in the users $HOME directory. 

At this time Gravity Sync does not support passphrases in RSA keyfiles. If you have a passphrase applied to your standard `.ssh/id_rsa` either remove it, or generate a new file and specify that key for use only by Gravity Sync.

Default setting in Gravity Sync is `.ssh/id_rsa`

#### `LOG_PATH=''`
Gravity Sync will place logs in the same folder as the script (identified as .cron and .log) but if you'd like to place these in a another location, you can do that by identifying the full path to the directory. (ex: `/full/path/to/logs`)

Default setting in Gravity Sync is `$HOME/${LOCAL_FOLDR}`

#### `SYNCING_LOG=''`
Gravity Sync will write a timestamp for any completed pull, push or restore job to this file. If you want to change the name of this file, you will also need to adjust the LOG_PATH variable above, otherwise your file will be remove during `update` operations.

Default setting in Gravity Sync is `gravity-sync.log`

#### `CRONJOB_LOG=''`
Gravity Sync will log the execution history of the previous automation task via Cron to this file. If you want to change the name of this file, you will also need to adjust the LOG_PATH variable above, otherwise your file will be remove during `update` operations.

This will have an impact to both the `./gravity-sync.sh automate` function and the `./gravity-sync.sh cron` functions. If you need to change this after running the automate function, either modify your crontab manually or delete the entry and re-run the automate function.

Default setting in Gravity Sync is `gravity-sync.cron`

#### `VERIFY_PASS=''`
Gravity Sync will prompt to verify user interactivity during push, restore, or config operations (that overwrite an existing configuration) with the intention that it prevents someone from accidentally automating in the wrong direction or overwriting data intentionally. If you'd like to automate a push function, or just don't like to be asked twice to do something distructive, then you can opt-out.

Default setting in Gravity Sync is 0, change to 1 to bypass this check.

#### `SKIP_CUSTOM=''`
Starting in v1.7.0, Gravity Sync manages the `custom.list` file that contains the "Local DNS Records" function within the Pi-hole interface. If you do not want to sync this setting, perhaps if you're doing a mutli-site deployment with differing local DNS settings, then you can opt-out of this sync.

Default setting in Gravity Sync is 0, change to 1 to exempt `custom.list` from replication.

#### `DATE_OUTPUT=''`      
*This feature has not been fully implemented, but the intent is to provide the ability to add timestamped output to each status indicator in the script output (ex: [2020-05-28 19:46:54] [EXEC] $MESSAGE).*

Default setting in Gravity Sync is 0, change to 1 to print timestamped output.

#### `BASH_PATH=''`
If you need to adjust the path to bash that is identified for automated execution via Crontab, you can do that here. This will only have an impact if changed before generating the crontab via the `./gravity-sync.sh automate` function. If you need to change this after the fact, either modify your crontab manually or delete the entry and re-run the automate function.

#### `PING_AVOID=''`
The `./gravity-sync.sh config` function will attempt to ping the remote host to validate it has a valid network connection. If there is a firewall between your hosts preventing ping replies, or you otherwise wish to skip this step, it can by bypassed here.

Default setting in Gravity Sync is 0, change to 1 to skip this network test.

## Execution
If you are just straight up unable to run the `gravity-sync.sh` file, make sure it's marked as an executable by Linux.

```bash
chmod +x gravity-sync.sh
```


## Updates
If you manually installed Gravity Sync via .zip or .tar.gz you will need to download and overwrite the `gravity-sync.sh` file with a newer version. If you've chosen this path, I won't lay out exactly what you'll need to do every time, but you should at least review the contents of the script bundle (specifically the example configuration file) to make sure there are no new additional files or required settings. 

At the very least, I would reccomend backing up your existing `gravity-sync` folder and then deploying a fresh copy each time you update, and then either creating a new .conf file or copying your old file over to the new folder.

### Development Builds
Starting in v1.7.2, you can easily flag if you want to receive the development branch of Gravity Sync when running the built in `./gravity-sync.sh update` function. Beginning in v1.7.4 `./gravity-sync.sh dev` will now toggle the dev flag on/off. No `touch` required, although it still works that way under the covers. 

To manually adjust the flag, create an empty file in the `gravity-sync` folder called `dev` and afterwards the standard `./gravity-sync.sh update` function will apply the correct updates.
```
cd gravity-sync
touch dev
./gravity-sync.sh update
```
Delete the `dev` file and update again to revert back to the stable/master branch.

This method for implementation is decidedly different than the configuration flags in the .conf file, as explained above, to make it easier to identify development systems.

### Updater Troubleshooting
If the built in updater doesn't function as expected, you can manually run the git commands that operate under the covers.
```
git fetch --all
git reset --hard origin/master
```
Use `origin/development` to pull that branch instead.

If your code is still not updating after this, reinstallation is suggested rather than spending all your time troubleshooting `git` commands.

## Automation
There are many automation methods available to run scripts on a regular basis of a Linux system. The one built into all of them is cron, but if you'd like to utilize something different then the principles are still the same.

If you prefer to still use cron but modify your settings by hand, using the entry below will cause the entry to run at the top and bottom of every hour (1:00 PM, 1:30 PM, 2:00 PM, etc) but you are free to dial this back or be more agressive if you feel the need.

```bash
crontab -e
*/30 * * * * /bin/bash /home/USER/gravity-sync/gravity-sync.sh pull > /home/USER/gravity-sync/gravity-sync.cron
```

## Troubleshooting
 
- If it doesn't kick off, you can manually execute a `git pull` while in the `gravity-sync` directory. 

If all else fails, delete the entire `gravity-sync` folder from your system and re-deploy. This will have no impact on your replicated databases. 

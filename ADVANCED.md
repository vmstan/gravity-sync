# Gravity Sync
## Advanced Configuration
The purpose of this guide is to break out the manual install instructions, and any advanced configuration flags, into a seperate document to limit confusion from the primary README. It is expected that users have read and are familiar with the process and concepts outlined in the primary README.

## Installation
If you don't trust `git` to install your software, or just like doing things by hand, that's fine. 

*Keep in mind that installing via this method means you won't be able to use Gravity Sync's built-in update mechanism.*

Download the latest release from [GitHub](https://github.com/vmstan/gravity-sync/releases) and extract the files to your *secondary* Pi-hole server.

```bash
cd ~
wget https://github.com/vmstan/gravity-sync/archive/v1.7.4.zip
unzip v1.7.4.zip -d gravity-sync
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

## Automation
There are many automation methods available to run scripts on a regular basis of a Linux system. The one built into all of them is cron, but if you'd like to utilize something different then the principles are still the same.

If you prefer to still use cron but modify your settings by hand, using the entry below will cause the entry to run at the top and bottom of every hour (1:00 PM, 1:30 PM, 2:00 PM, etc) but you are free to dial this back or be more agressive if you feel the need.

```bash
crontab -e
*/30 * * * * /bin/bash /home/USER/gravity-sync/gravity-sync.sh pull > /home/USER/gravity-sync/gravity-sync.cron
```

## Troubleshooting
If you are just straight up unable to run the `gravity-sync.sh` file, make sure it's marked as an executable by Linux.

```bash
chmod +x gravity-sync.sh
```

If you are getting errors about missing SSH or RSYNC when you run your first `compare` or `pull` operation, and you're using an ultra-lightweight distro like DietPi, make sure they are installed on the base operating system.

- If your script prompts for a password on the remote system, make sure that your user account is setup not to require passwords in the sudoers file.
- If you use a non-standard SSH port to connect to your primary Pi-hole, you can add `SSH_PORT='123'` to the bottom of your `gravity-sync.conf` file. (Subsitute 123 for your non-standard port.) This will overwrite the `SSH_PORT=22` at the top of the script as it is imported later in the execution. 
- If you'd like to know what version of the script you have running by running `./gravity-sync.sh version` 
- If the update script fails, make sure you did your original deployment via `git clone` and not a manual install. 
- If it doesn't kick off, you can manually execute a `git pull` while in the `gravity-sync` directory. 

If all else fails, delete the entire `gravity-sync` folder from your system and re-deploy. This will have no impact on your replicated databases. 

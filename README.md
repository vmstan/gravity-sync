# Gravity Sync

For more information visit [https://vmstan.com/gravity-sync/](https://vmstan.com/gravity-sync/)

The scripts assumes you have one "master" Pihole as the primary place you make all your configuration changes, such as whitelist, blacklist, group management, and blocklist settings. After the script executes it will copy the gravity.db from the master to any secondary nodes you configure it to run on.

### Prereqs

- This script is designed to work with Pihole 5.0 GA
- This script has been tested with Ubuntu 20.04 and Rasbian

You'll need to generate an SSH key for your secondary Pihole user and copy it to your primary Pihole. This will allow you to connect to and copy the gravity.db file without needing a password each time.

```
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub USERNAME@PRIMARYPI
```

### Installation

From your *secondary* Pi, login via SSH and copy the gravity-sync.sh script to your user. In this example we will use git to keep the latest copy of the script on your server.

```
cd ~
git clone https://github.com/vmstan/gravity-sync.git
cd gravity-sync
```

Please note the script **must** be run from a folder in your user home directory (ex: /home/pi/gravity-sync) -- I wouldn't suggest changing the folder name.

### Configuration

After you clone the base configuration, you will need to create a configuration file called `gravity-sync.conf` in the same folder as the script.

```
vim gravity-sync.conf
```

If you don't like VIM, use NANO or your text editor of choice.

Paste the following into your file, making sure to change the IP (or DNS name) and user account to authenticate to the master Pi.

```
REMOTE_HOST='192.168.7.5'
REMOTE_USER='pi'
```

Now test the script. I suggest making a subtle change to a whitelist/blacklist on your primary Pihole, such as a description field, and then seeing if the change propagates to your secondary.

```
./gravity-sync.sh pull
```

You will now have overwritten your running gravity.db on the secondary Pihole after creating a copy (gravity.db.backup) in the /etc/pihole directory. The script will also keep a copy of the last sync'd gravity.db from the master, in the gravity-sync folder (gravity.db.last) should you need it. Lastly, a file called gravity-sync.log will be created in the sync folder, with the date the script was last executed appended to the bottom.

### Failover

There is an option in the script to push from the secondary Pihole back to the primary. This would be useful in a situation where your primary is down for an extended period of time, and you have list changes you want to force back to the primary when it comes online.

```
./gravity-sync.sh push
```

Please note that the "push" option does not make any backups of anything. There is a warning about potental data loss before executing this function. This function purposefuly asks for user interaction to avoid being accidentally automated.

### Updates

If you do a `git pull` while in the `gravity-sync` directory you should be able to levegage git to update to the latest copy of the script. Your changes to the .conf file, logs and backups should be uneffected by this.

### Automation

I've automated by synchronization using Crontab. If you'd like to keep this a manual process then ignore this section. By default my script will run at the top and bottom of every hour (1:00 PM, 1:30 PM, 2:00 PM, etc) but you can dial this back if you feel this is too aggressive.

```
crontab -e
*/30 * * * * /home/USER/gravity-sync/gravity-sync.sh pull >/dev/null 2>&1
```

Make another small adjustment to your primary settings. Now just wait until the annointed hour, and see if your changes have been synchronized. If so, profit!

If not, start from the beginning.

From this point forward any blocklist changes you make to the primary will reflect on the secondary within 30 minutes.

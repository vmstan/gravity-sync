# Gravity Sync

For more information visit [https://vmstan.com/gravity-sync/](https://vmstan.com/gravity-sync/)

The scripts assumes you have one "master" Pihole as the primary place you make all your configuration changes, such as whitelist, blacklist, group management, and blocklist settings. After the script executes it will copy the gravity.db from the master to any secondary nodes you configure it to run on.

### Installation

From your *secondary* Pi, login via SSH and copy the gravity-sync.sh script to your user. In this example we will use git to keep the latest copy of the script on your server.

```
cd ~
git clone https://github.com/vmstan/gravity-sync.git
cd gravity-sync
```

Please note the script **must** be run from a folder in your user home directory (ex: /home/pi/gravity-sync)

### Configuration

You will need to make sure your secondary Pihole is setup to authenticate to your primary Pihole via certificates. 

```
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub USERNAME@PRIMARYPI
```

Modify your copy of the script to specify the username and address of the primary Pi.

```
vim gravity-sync.sh
```

If you don't like VIM, use NANO or your text editor of choice.

Now test the script. I suggest making a subtle change to a whitelist/blacklist on your primary Pihole, such as a description field, and then seeing if the change propagates to your secondary.

```
./gravity-sync.sh pull
```


#Changelog

## 1.7

**Features**

- Gravity Sync will now manage the custom.list file that contains the "Local DNS Records" function within the Pi-hole interface.
- If you do not want this feature enabled it can be bypassed by adding a SKIP_CUSTOM='1' to your .conf file. 
- Sync will be trigged during a pull operation if there are changes to either file.

**Known Issues**

- No new Star Trek references.

## 1.6

**Features**

- New ./gravity-sync restore function will bring a previous version of the gravity.db back from the dead.
- Changes way that GS prompts for data input and how confirmation prompts are handled.
- Adds ability to override verification of push, restore or config reset, see .example file for details.
- Five new Star Trek references.

**Bug Fixes**
- New functions add consistency in status output.

## 1.5

## 1.4

### 1.4.3
### 1.4.2
### 1.4.1

## 1.3

### 1.3.4
### 1.3.3
### 1.3.2
### 1.3.1

## 1.2

### 1.2.5
### 1.2.4
### 1.2.3
### 1.2.2
### 1.2.1

## 1.1

Moved from Gist.

### 1.1.6
### 1.1.5
### 1.1.4
### 1.1.3
### 1.1.2

## 1.0

Initial release, to Andrew, internal Slack and eventually [vmstan.com](https://vmstan.com/gravity-sync)

```
echo 'Copying gravity.db from HA primary'
rsync -e 'ssh -p 22' ubuntu@192.168.7.5:/etc/pihole/gravity.db /home/pi/gravity-sync
echo 'Replacing gravity.db on HA secondary'
sudo cp /home/pi/gravity-sync/gravity.db /etc/pihole/ echo 'Reloading configuration of HA secondary FTLDNS from new gravity.db'
pihole restartdns reload-lists
echo 'Cleaning up things'
mv /home/pi/gravity-sync/gravity.db /home/pi/gravity- sync/gravity.db.last
```

For real, that's it. 7 lines.
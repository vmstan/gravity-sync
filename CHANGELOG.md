#Changelog

## 1.7

## 1.6

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

### 1.1.6
### 1.1.5
### 1.1.4
### 1.1.3
### 1.1.2

## 1.0

Initial release, to [vmstan.com](https://vmstan.com/gravity-sync)

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
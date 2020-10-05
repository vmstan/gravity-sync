# GRAVITY SYNC BY VMSTAN #####################
# gs-hostprep.sh #############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code will be called from a curl call via installation instructions

# Run this script on your primary Pi-hole to aid in preparing for Gravity Sync installation.

echo -e "Checking for required software"

if hash ssh
then
    echo -e "SSH Client Detected"
else
    echo -e "SSH Client Missing"
fi

if hash rsync
then
    echo -e "RSYNC Detected"
else
    echo -e "RSYNC Missing"
fi

if hash sqlite3
then
    echo -e "SQLITE3 Detected"
else
    echo -e "SQLLITE3 Missing"
fi


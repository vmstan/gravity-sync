# GRAVITY SYNC BY VMSTAN #####################
# gs-hostprep.sh #############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code will be called from a curl call via installation instructions

# Run this script on your primary Pi-hole to aid in preparing for Gravity Sync installation.

# Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
BOLD='\033[1m'
NC='\033[0m'

CROSSCOUNT="0"

if [ ! "$EUID" -ne 0 ]
then 
    echo -e "[${RED}✗${NC}] Running as Root"
    CROSSCOUNT=$((CROSSCOUNT+1))
else
    echo -e "[${GREEN}✓${NC}] Not Running as Root"
fi

echo -e "Checking for required software"

if hash ssh
then
    echo -e "[${GREEN}✓${NC}] SSH Detected"
else
    echo -e "[${RED}✗${NC}] SSH Missing"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

if hash rsync
then
    echo -e "[${GREEN}✓${NC}] RSYNC Detected"
else
    echo -e "[${RED}✗${NC}] RSYNC Missing"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

if hash sqlite3
then
    echo -e "[${GREEN}✓${NC}] SQLITE3 Detected"
else
    echo -e "[${RED}✗${NC}] SQLLITE3 Missing"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

if [ "$CROSSCOUNT" != "0" ]
then
    echo -e "Checks failed"
else
    echo -e "All good!"
fi


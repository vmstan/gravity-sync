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

# Variables
CROSSCOUNT="0"
CURRENTUSER=$(whoami)

# Header
echo -e "${YELLOW}Gravity Sync 3.0 - Deployment Scan${NC}"

# Check Root
if [ ! "$EUID" -ne 0 ]
then 
    echo -e "[${RED}✗${NC}] Running as Root"
    CROSSCOUNT=$((CROSSCOUNT+1))
else
    echo -e "[${GREEN}✓${NC}] Not Running as Root"
fi

# Check Sudo
sudo --validate
if [ "$?" != "0" ]
then
    echo -e "[${RED}✗${NC}] No Sudo Powers for ${CURRENTUSER}"
    CROSSCOUNT=$((CROSSCOUNT+1))
else
    echo -e "[${GREEN}✓${NC}] Sudo Powers Valid"
fi

# Check OpenSSH
if hash ssh
then
    echo -e "[${GREEN}✓${NC}] OpenSSH Detected"
else
    echo -e "[${RED}✗${NC}] OpenSSH Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Rsync
if hash rsync
then
    echo -e "[${GREEN}✓${NC}] RSYNC Detected"
else
    echo -e "[${RED}✗${NC}] RSYNC Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check SQLITE3
if hash sqlite3
then
    echo -e "[${GREEN}✓${NC}] SQLITE3 Detected"
else
    echo -e "[${RED}✗${NC}] SQLITE3 Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check GIT
if hash git
then
    echo -e "[${GREEN}✓${NC}] GIT Detected"
else
    echo -e "[${RED}✗${NC}] GIT Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Pihole
if hash pihole
then
    echo -e "[${GREEN}✓${NC}] Pi-Hole Detected"
else
    echo -e "[${RED}✗${NC}] Pi-hole Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Combine Outputs
if [ "$CROSSCOUNT" != "0" ]
then
    echo -e "${RED}${CROSSCOUNT}${NC} failures detected, correct these errors before deploying Gravity Sync!"
else
    echo -e "[${BLUE}>${NC}] Creating Sudoers.d File"
    touch /tmp/gs-nopasswd.sudo
    echo -e "${CURRENTUSER} ALL=(ALL) NOPASSWD: /etc/pihole" > /tmp/gs-nopasswd.sudo
    sudo install -m 0440 /tmp/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
    echo -e "${CYAN}This host is prepared to deploy Gravity Sync!${NC}"
fi

exit
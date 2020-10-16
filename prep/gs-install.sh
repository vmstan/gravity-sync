# GRAVITY SYNC BY VMSTAN #####################
# gs-install.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code will be called from a curl call via installation instructions

# Run this script on your primary Pi-hole to aid in preparing for Gravity Sync installation.

set -e

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
echo -e "${YELLOW}Gravity Sync - Automated Installation${NC}"
echo -e "Visit ${CYAN}https://github.com/vmstan/gravity-sync${NC} for assistance"
echo -e "##############################################"
echo -e "Initalizing Short Range Sensors"

# Check Root
if [ ! "$EUID" -ne 0 ]
then 
    echo -e "[${GREEN}✓${NC}] Running as Root"
    LOCALADMIN=""
else
    if hash sudo 2>/dev/null
    then
        echo -e "[${GREEN}✓${NC}] Sudo Utility Detected"
        # Check Sudo
        sudo --validate
        if [ "$?" != "0" ]
        then
            echo -e "[${RED}✗${NC}] No Sudo Powers for ${CURRENTUSER}"
            CROSSCOUNT=$((CROSSCOUNT+1))
            LOCALADMIN="nosudo"
        else
            echo -e "[${GREEN}✓${NC}] Sudo Powers Valid"
            LOCALADMIN="sudo"
        fi
    else
        echo -e "[${RED}✗${NC}] Sudo Utility Not Installed"
        CROSSCOUNT=$((CROSSCOUNT+1))
    fi
    echo -e "[${RED}✗${NC}] No Administrator Powers Detected"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check OpenSSH
if hash ssh 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] OpenSSH Detected"
else
    echo -e "[${RED}✗${NC}] OpenSSH Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Rsync
if hash rsync 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] RSYNC Detected"
else
    echo -e "[${RED}✗${NC}] RSYNC Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check SQLITE3
if hash sqlite3 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] SQLITE3 Detected"
else
    echo -e "[${RED}✗${NC}] SQLITE3 Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check GIT
if hash git 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] GIT Detected"
else
    echo -e "[${RED}✗${NC}] GIT Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Pihole
if hash pihole 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] Pi-Hole Local Install Detected"
else
    if hash docker 2>/dev/null
    then
        echo -e "[${GREEN}✓${NC}] Docker Binary Install Detected"
        
        if [ "$LOCALADMIN" == "sudo" ]
        then
            FTLCHECK=$(sudo docker container ls | grep 'pihole/pihole')
        elif [ "$LOCALADMIN" == "nosudo" ]
        then
            echo -e "[${RED}✗${NC}] Unable to Detect Pi-hole Install"
            CROSSCOUNT=$((CROSSCOUNT+1))
        else
            FTLCHECK=$(docker container ls | grep 'pihole/pihole')
        fi
        
        if [ "$FTLCHECK" != "" ]
        then
            echo -e "[${GREEN}✓${NC}] Pi-Hole Docker Container Detected"
        else
            echo -e "[${RED}✗${NC}] Unable to Detect Pi-hole Install"
            CROSSCOUNT=$((CROSSCOUNT+1))
        fi
    else
        echo -e "[${RED}✗${NC}] Unable to Detect Pi-hole Install"
        CROSSCOUNT=$((CROSSCOUNT+1))
    fi
fi

# Combine Outputs
if [ "$CROSSCOUNT" != "0" ]
then
    echo -e "[${PURPLE}!${NC}] ${RED}${CROSSCOUNT}${NC} failures detected, correct these errors before deploying Gravity Sync!"
else
    echo -e "[${CYAN}>${NC}] Creating Sudoers.d File"
    touch /tmp/gs-nopasswd.sudo
    echo -e "${CURRENTUSER} ALL=(ALL) NOPASSWD: ALL" > /tmp/gs-nopasswd.sudo
    sudo install -m 0440 /tmp/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd

		if [ "$GS_INSTALL" != "secondary" ]
		then
			echo -e "[${YELLOW}i${NC}] This host is prepared to use Gravity Sync, you may log off now!"
            echo -e "[${YELLOW}i${NC}] Run this script again on your secondary Pi-hole host to proceed."
            echo -e "[${YELLOW}i${NC}] Visit https://github.com/vmstan/gravity-sync for more instructions."
        else
            echo -e "[${CYAN}>${NC}] Creating Gravity Sync Directories"
            git clone https://github.com/vmstan/gravity-sync.git $HOME/gravity-sync
            echo -e "[${YELLOW}i${NC}] This host is now prepared to configure Gravity Sync!"
            echo -e "[${YELLOW}i${NC}] Please run './gravity-sync configure' from $HOME/gravity-sync"
            echo -e "[${YELLOW}i${NC}] Visit https://github.com/vmstan/gravity-sync for more instructions."
		fi
        
fi

exit
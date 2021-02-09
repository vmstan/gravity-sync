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
PHFAILCOUNT="0"
CURRENTUSER=$(whoami)

# Header
echo -e ""
echo -e "         ..::-----::..                          ..::------::.         "
echo -e "      .:----:::::::----:.                    .:::--:::::---===-:      "
echo -e "    :---:.           .:---:                +##+:.          .:-===-.   "
echo -e "  .---:.                :---:            -*##*:               .-===:  "
echo -e " .---.                    :---:        -++*+.                   .==+- "
echo -e " ---.          =            :---:    :====.           -          .=++."
echo -e ":--:          -=-.            :---::---:.            -=-.         :++="
echo -e "---.      .:-=====-:..          ------.          .:-=====-:..     .+++"
echo -e "---.        .:===-.            :------:            .:===-.        :+++"
echo -e ".--:          .=:            :---:  :---:             =:          -++-"
echo -e " :--:          ..          .---:.     :--::           ..         -=+= "
echo -e "  :--:                   .---:.         :-:::                   -===. "
echo -e "   :---:               :---:              :::::              .:====   "
echo -e "     :---::..     ..::---:.                 ::::::..     ..:-===-.    "
echo -e "       .::-----------::.                      .::---------===-:       "
echo -e ""
echo -e "${YELLOW}Gravity Sync by ${BLUE}@vmstan${NC}"
echo -e "${CYAN}https://github.com/vmstan/gravity-sync${NC}"
echo -e "========================================================"
echo -e "[${GREEN}✓${NC}] Checking Short Range Sensors"

# Check Root
echo -e "[${YELLOW}i${NC}] ${YELLOW}Validating System Authorization${NC}"
if [ ! "$EUID" -ne 0 ]
then
    echo -e "[${GREEN}✓${NC}] Current User (${CURRENTUSER}) is ROOT"
    LOCALADMIN="root"
else
    if hash sudo 2>/dev/null
    then
        echo -e "[${GREEN}✓${NC}] Sudo Utility Detected"
        # Check Sudo
        sudo --validate
        if [ "$?" != "0" ]
        then
            echo -e "[${RED}✗${NC}] Current User (${CURRENTUSER}) Cannot SUDO"
            CROSSCOUNT=$((CROSSCOUNT+1))
            LOCALADMIN="nosudo"
        else
            echo -e "[${GREEN}✓${NC}] Current User (${CURRENTUSER}) Has SUDO Powers"
            LOCALADMIN="sudo"
        fi
    else
        echo -e "[${RED}✗${NC}] Sudo Utility Not Detected"
        CROSSCOUNT=$((CROSSCOUNT+1))
        LOCALADMIN="nosudo"
    fi
    
    if [ "$LOCALADMIN" != "sudo" ]
    then
        echo -e "[${RED}✗${NC}] Current User (${CURRENTUSER}) Cannot SUDO"
        CROSSCOUNT=$((CROSSCOUNT+1))
        LOCALADMIN="nosudo"
    fi
fi

echo -e "[${YELLOW}i${NC}] ${YELLOW}Scanning for Required Components${NC}"
# Check OpenSSH
if hash ssh 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] OpenSSH Binaries Detected"
else
    echo -e "[${RED}✗${NC}] OpenSSH Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Rsync
if hash rsync 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] RSYNC Binaries Detected"
else
    echo -e "[${RED}✗${NC}] RSYNC Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Sudo
if hash sudo 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] SUDO Binaries Detected"
else
    echo -e "[${RED}✗${NC}] SUDO Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Crontab
if hash crontab 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] CRONTAB Binaries Detected"
else
    echo -e "[${RED}✗${NC}] CRONTAB Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check SQLITE3
if hash sqlite3 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] SQLITE3 Binaries Detected"
else
    echo -e "[${RED}✗${NC}] SQLITE3 Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check GIT
if hash git 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] GIT Binaries Detected"
else
    echo -e "[${RED}✗${NC}] GIT Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

echo -e "[${YELLOW}i${NC}] ${YELLOW}Performing Warp Core Diagnostics${NC}"
# Check Pihole
if hash pihole 2>/dev/null
then
    echo -e "[${GREEN}✓${NC}] Local Pi-hole Install Detected"
else
    echo -e "[${PURPLE}!${NC}] ${PURPLE}No Local Pi-hole Install Detected${NC}"
    # echo -e "[${PURPLE}!${NC}] ${PURPLE}Attempting To Compensate${NC}"
    if hash docker 2>/dev/null
    then
        echo -e "[${GREEN}✓${NC}] Docker Binaries Detected"
        
        if [ "$LOCALADMIN" == "sudo" ]
        then
            FTLCHECK=$(sudo docker container ls | grep 'pihole/pihole')
        elif [ "$LOCALADMIN" == "nosudo" ]
        then
            echo -e "[${PURPLE}!${NC}] ${PURPLE}No Docker Pi-hole Container Detected (unable to scan)${NC}"
            # CROSSCOUNT=$((CROSSCOUNT+1))
            PHFAILCOUNT=$((PHFAILCOUNT+1))
        else
            FTLCHECK=$(docker container ls | grep 'pihole/pihole')
        fi
        
        if [ "$LOCALADMIN" != "nosudo" ]
        then
            if [ "$FTLCHECK" != "" ]
            then
                echo -e "[${GREEN}✓${NC}] Pi-Hole Docker Container Detected"
            else
                echo -e "[${PURPLE}!${NC}] ${PURPLE}No Docker Pi-hole Container Detected${NC}"
                # CROSSCOUNT=$((CROSSCOUNT+1))
                PHFAILCOUNT=$((PHFAILCOUNT+1))
            fi
        fi
    elif hash podman 2>/dev/null
    then
        echo -e "[${GREEN}✓${NC}] Podman Binaries Detected"
        
        if [ "$LOCALADMIN" == "sudo" ]
        then
            FTLCHECK=$(sudo podman container ls | grep 'pihole/pihole')
        elif [ "$LOCALADMIN" == "nosudo" ]
        then
            echo -e "[${PURPLE}!${NC}] ${PURPLE}No Podman Pi-hole Container Detected (unable to scan)${NC}"
            # CROSSCOUNT=$((CROSSCOUNT+1))
            PHFAILCOUNT=$((PHFAILCOUNT+1))
        else
            FTLCHECK=$(podman container ls | grep 'pihole/pihole')
        fi
        
        if [ "$LOCALADMIN" != "nosudo" ]
        then
            if [ "$FTLCHECK" != "" ]
            then
                echo -e "[${GREEN}✓${NC}] Pi-Hole Podman Container Detected"
    else
                echo -e "[${PURPLE}!${NC}] ${PURPLE}No Podman Pi-hole Container Detected${NC}"
                # CROSSCOUNT=$((CROSSCOUNT+1))
                PHFAILCOUNT=$((PHFAILCOUNT+1))
            fi
        fi
    else
        # echo -e "[${RED}✗${NC}] No Local Pi-hole Install Detected"
        echo -e "[${PURPLE}!${NC}] ${PURPLE}No Docker Pi-hole Alternative Detected${NC}"
        # CROSSCOUNT=$((CROSSCOUNT+1))
        PHFAILCOUNT=$((PHFAILCOUNT+1))
    fi
fi

if [ "$PHFAILCOUNT" != "0" ]
then
    echo -e "[${RED}✗${NC}] No Usable Pi-hole Install Detected"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# echo -e "[${YELLOW}i${NC}] ${YELLOW}Target Folder Analysis${NC}"
if [ "$GS_INSTALL" == "secondary" ]
then
    if [ "$LOCALADMIN" == "sudo" ]
    then
        THISDIR=$(pwd)
        if [ "$THISDIR" != "$HOME" ]
        then
            echo -e "[${RED}✗${NC}] ${CURRENTUSER} Must Install to $HOME"
            echo -e "[${PURPLE}!${NC}] ${PURPLE}Use 'root' Account to Install in $THISDIR${NC}"
            CROSSCOUNT=$((CROSSCOUNT+1))
        fi
    fi
fi

if [ -d gravity-sync ]
then
    echo -e "[${RED}✗${NC}] Folder gravity-sync Already Exists"
    echo -e "[${PURPLE}!${NC}] ${PURPLE}Use './gravity-sync.sh update' to Update Instead${NC}"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

echo -e "[${YELLOW}i${NC}] ${YELLOW}Status Report${NC}"
# Combine Outputs
if [ "$CROSSCOUNT" != "0" ]
then
    echo -e "[${RED}*${NC}] ${RED}${CROSSCOUNT} Critical Issue(s) Detected${NC}"
    echo -e "[${PURPLE}!${NC}] ${PURPLE}Please Correct Failures and Re-Execute${NC}"
    echo -e "[${YELLOW}i${NC}] ${YELLOW}Installation Exiting (without changes)${NC}"
else
    echo -e "[${YELLOW}i${NC}] ${YELLOW}Executing Gravity Sync Deployment${NC}"
    
    if [ "$LOCALADMIN" == "sudo" ]
    then
        echo -e "[${BLUE}>${NC}] Creating Sudoers.d File"
        touch /tmp/gs-nopasswd.sudo
        echo -e "${CURRENTUSER} ALL=(ALL) NOPASSWD: ALL" > /tmp/gs-nopasswd.sudo
        sudo install -m 0440 /tmp/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
    fi
    
    if [ "$GS_INSTALL" != "secondary" ]
    then
        echo -e "[${YELLOW}i${NC}] Gravity Sync Preperation Complete"
        echo -e "[${YELLOW}i${NC}] Execute on Installer on Secondary"
        echo -e "[${YELLOW}i${NC}] Check Documentation for Instructions"
        echo -e "[${YELLOW}i${NC}] Installation Exiting (without changes)"
    else
        echo -e "[${BLUE}>${NC}] Creating Gravity Sync Directories"
            if [ "$GS_DEV" != "" ]
            then
                git clone -b ${GS_DEV} https://github.com/vmstan/gravity-sync.git
            else
                git clone https://github.com/vmstan/gravity-sync.git
            fi
        echo -e "[${BLUE}>${NC}] Starting Gravity Sync Configuration"
        echo -e "========================================================"
        ./gravity-sync/gravity-sync.sh configure <&1
        # echo -e "[${YELLOW}i${NC}] This host is now prepared to configure Gravity Sync!"
        # echo -e "[${YELLOW}i${NC}] Please run './gravity-sync configure' from $HOME/gravity-sync"
        # echo -e "[${YELLOW}i${NC}] Visit https://github.com/vmstan/gravity-sync for more instructions."
    fi
    
fi

exit
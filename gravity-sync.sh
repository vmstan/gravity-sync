#!/bin/bash

# Gravity Sync by vmstan
VERSION='1.1.1'

# Must execute from a location in the home folder of the user who own's it (ex: /home/pi/gravity-sync)
# Configure certificate based SSH authentication between the Pihole HA nodes - it does not use passwords
# Tested against Pihole 5.0 GA on Raspbian Buster and Ubuntu 20.04, but it should work on most configs
# More installation instructions available at https://vmstan.com/gravity-sync
# For the latest version please visit https://github.com/vmstan/gravity-sync under Releases

# You must change the REMOTE_HOST and REMOTE_USER variables below to match your configuration

# STANDARD SETTINGS
REMOTE_HOST='192.168.7.5'
REMOTE_USER='ubuntu'

# PUSH SETTINGS


# CUSTOMIZATION
LOCAL_FOLDR='gravity-sync' # see above
SYNCING_LOG='gravity-sync.log' # see above

# PIHOLE DEFAULTS
PIHOLE_DIR='/etc/pihole'  # default install directory
GRAVITY_FI='gravity.db' # this should not change

# SCRIPT COLORS
RED='\033[91m'
GREEN='\033[92m'
CYAN='\033[96m'
NC='\033[0m'

##############################################

# print title
# echo -e "${GREEN}Gravity Sync ${VERSION}${NC}"

echo -e "${CYAN}Validating configuration${NC}"

# check to see if logging/backup directory is available
if [ -d ~/${LOCAL_FOLDR} ]
then
    echo -e "${GREEN}Success${NC}: Required directory ~/{LOCAL_FOLDR} is present"
else
	echo -e "${RED}Failure${NC}: Required directory ~/{LOCAL_FOLDR} is missing"
	exit
fi

case $# in
   0)
	echo -e "You must define the direction you want to replicate ${GRAVITY_FI}"
	echo "Usage: $0 {pull|push}"
	echo -e "${RED}Pull${NC} will copy the primary blocklists ($REMOTE_HOST) to this server"
	echo -e "${RED}Push${NC} will force any changes made on this server to the primary"
      	exit 1
	;;
   1)
      case $1 in
	pull)

	echo -e "${CYAN}Copying remote ${GRAVITY_FI} from ${REMOTE_HOST}${NC}"
	rsync -v -e 'ssh -p 22' ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI} ~/${LOCAL_FOLDR}/${GRAVITY_FI}
	echo -e "${CYAN}Replacing gravity.db on HA secondary${NC}"
	sudo mv -v ${PIHOLE_DIR}/${GRAVITY_FI} ${PIHOLE_DIR}/${GRAVITY_FI}.backup
	sudo cp -v ~/${LOCAL_FOLDR}/${GRAVITY_FI} ${PIHOLE_DIR}
	sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}
	sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}
	echo -e "${CYAN}Reloading configuration of HA secondary FTLDNS from new gravity.db${NC}"
	pihole restartdns reloadlists
	pihole restartdns
	echo -e "${CYAN}Cleaning up things${NC}"
	mv -v ~/${LOCAL_FOLDR}/${GRAVITY_FI} ~/${LOCAL_FOLDR}/${GRAVITY_FI}.last
	date >> ~/${LOCAL_FOLDR}/${SYNCING_LOG}
	echo -e "${GREEN}gravity.db pull completed${NC}"
 	;;

	push)
	echo -e "${RED}WARNING - DATA LOSS POSSIBLE${NC}"
	echo -e "Are you sure you want to overwrite the primary node configuration on ${REMOTE_HOST}?"
	select yn in "Yes" "No"; do
	    case $yn in
	        Yes )
			echo "Replacing gravity.db on primary"
			echo -e "${CYAN}Copying local ${GRAVITY_FI} to ${REMOTE_HOST}${NC}"
			rsync --rsync-path="sudo rsync" -v -e 'ssh -p 22' ${PIHOLE_DIR}/${GRAVITY_FI} ${REMOTE_USER}@${REMOTE_HOST}:${PIHOLE_DIR}/${GRAVITY_FI}
			echo -e "${CYAN}Applying permissions to remote gravity.db${NC}"
			ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chmod 644 ${PIHOLE_DIR}/${GRAVITY_FI}"
			ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo chown pihole:pihole ${PIHOLE_DIR}/${GRAVITY_FI}"
			echo -e "${CYAN}Reloading configuration on remote FTLDNS${NC}"
			ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns reloadlists'
			ssh ${REMOTE_USER}@${REMOTE_HOST} 'pihole restartdns'
			echo -e "${GREEN}gravity.db push completed${NC}"
			break;;
	        No )
			echo "No changes have been made"
			exit;;
	    esac
	done
	;;

	*)
	echo -e "${RED}'$1' is not a valid argument${NC}"
        echo "Usage: $0 {pull|push}"
        exit 2
	;;
      esac
      ;;
  *)
      echo -e "${RED}Too many arguments provided ($#)${NC}"
      echo "Usage: $0 {pull|push}"
      exit 3
      ;;
esac
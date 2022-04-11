#!/usr/bin/env bash

# GRAVITY SYNC BY VMSTAN #####################
# GS 3.x to 4.0 Upgrade Utility ##############

# Run only to upgrade your existing Gravity Sync 3.x installation to 4.0 format
PROGRAM='Gravity Sync'

GS_FILEPATH=$(realpath $0)
LOCAL_FOLDR=$(dirname $GS_FILEPATH)

GS_ETC_PATH="/etc/gravity-sync"
GS_GRAVITY_FI_MD5_LOG='gs-gravity.md5'
GS_CUSTOM_DNS_MD5_LOG='gs-clist.md5'
GS_CNAME_CONF_MD5_LOG='gs-cname.md5'

OS_DAEMON_PATH='/etc/systemd/system'

## Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
BOLD='\033[1m'
NC='\033[0m'

## Message Codes
FAIL="${RED}✗${NC}"
WARN="${PURPLE}!${NC}"
GOOD="${GREEN}✓${NC}"
STAT="${CYAN}∞${NC}"
INFO="${YELLOW}»${NC}"
INF1="${CYAN}›${NC}"
NEED="${BLUE}?${NC}"
LOGO="${PURPLE}∞${NC}"

## Echo Stack
### Informative
function echo_info {
    echo -e "${INFO} ${YELLOW}${MESSAGE}${NC}"
}

function echo_prompt {
    echo -e "${INF1} ${CYAN}${MESSAGE}${NC}"
}

### Warning
function echo_warn {
    echo -e "${WARN} ${PURPLE}${MESSAGE}${NC}"
}

### Executing
function echo_stat {
    echo -en "${STAT} ${MESSAGE}"
}

### Success
function echo_good {
    echo -e "\r${GOOD} ${MESSAGE}"
}

### Success
function echo_good_clean {
    echo -e "\r${GOOD} ${MESSAGE}"
}

### Failure
function echo_fail {
    echo -e "\r${FAIL} ${MESSAGE}"
}

### Request
function echo_need {
    echo -en "${NEED} ${BOLD}${MESSAGE}:${NC} "
}

### Indent
function echo_over {
    echo -e "  ${MESSAGE}"
}

### Gravity Sync Logo
function echo_grav {
    echo -e "${LOGO} ${BOLD}${MESSAGE}${NC}"
}

### Lines
function echo_blank {
    echo -e ""
}

## Error Validation
function error_validate {
    if [ "$?" != "0" ]; then
        echo_fail
        exit 1
    else
        echo_good
    fi
}

function start_gs_no_config {
    MESSAGE="Gravity Sync 3.x to 4.0 Migration Utility"
    echo_grav
}

function check_old_version {
    MESSAGE="Checking for 3.x Configuration File"
    echo_stat

    if [ -f settings/gravity-sync.conf ]; then
        echo_good
    else
        echo_fail
        exit 1
    fi

}

function install_new_gravity {
    MESSAGE="Installing Gravity Sync 4.0"
    echo_info

    if [ -d /etc/gravity-sync/.gs ]; then
        MESSAGE="Removing existing GitHub cache"
        echo_stat
        sudo rm -fr /etc/gravity-sync/.gs
        error_validate
    fi

    if [ ! -d /etc/gravity-sync ]; then
        MESSAGE="Creating new configuration directory"
        echo_stat
        sudo mkdir /etc/gravity-sync
        error_validate
    fi

    MESSAGE="Validating configuration directory permissions"
    echo_stat
    sudo chmod 775 /etc/gravity-sync
    error_validate

    if [ -f /usr/local/bin/gravity-sync ]; then
        MESSAGE="Removing old Gravity Sync binary"
        echo_stat
        sudo rm -f /usr/local/bin/gravity-sync
        error_validate
    fi

    MESSAGE="Creating new GitHub cache"
    echo_prompt

    sudo git clone https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
    
    # MESSAGE="Enabling beta updates"
    # echo_stat
    # sudo touch /etc/gravity-sync/.gs/dev
    # echo -e "BRANCH='origin/4.0.0'" | sudo tee /etc/gravity-sync/.gs/dev 1> /dev/null
    # error_validate

    sudo cp /etc/gravity-sync/.gs/gravity-sync /usr/local/bin
}

function upgrade_to_4 {
    MESSAGE="Migrating Previous Configuration"
    echo_info
    
    MESSAGE="Transferring SSH keys"
    sudo cp $HOME/.ssh/id_rsa /etc/gravity-sync/gravity-sync.rsa
    sudo cp $HOME/.ssh/id_rsa.pub /etc/gravity-sync/gravity-sync.rsa.pub
    error_validate

    REMOTE_HOST=''
    REMOTE_USER=''

    PIHOLE_DIR=''
    RIHOLE_DIR=''
    DNSMAQ_DIR=''
    RNSMAQ_DIR=''
    FILE_OWNER=''
    RILE_OWNER=''
    DOCKER_CON=''
    ROCKER_CON=''

    MESSAGE="Reviewing old configuration file settings"
    echo_stat
    source settings/gravity-sync.conf
    error_validate

    MESSAGE="Creating new configuration file from template"
    echo_stat
    sudo cp /etc/gravity-sync/.gs/templates/gravity-sync.conf.example /etc/gravity-sync/gravity-sync.conf
    error_validate
    
    LOCAL_PIHOLE_DIRECTORY=${PIHOLE_DIR}
    REMOTE_PIHOLE_DIRECTORY=${RIHOLE_DIR}
    LOCAL_DNSMASQ_DIRECTORY=${DNSMAQ_DIR}
    REMOTE_DNSMASQ_DIRECTORY=${RNSMAQ_DIR}
    LOCAL_FILE_OWNER=${FILE_OWNER}
    REMOTE_FILE_OWNER=${RILE_OWNER}
    LOCAL_DOCKER_CONTAINER=${DOCKER_CON}
    REMOTE_DOCKER_CONTAINER=${ROCKER_CON}

    MESSAGE="Migrating remote host settings"
    echo_stat
    sudo sed -i "/REMOTE_HOST=''/c\REMOTE_HOST='${REMOTE_HOST}'" /etc/gravity-sync/gravity-sync.conf
    error_validate
    
    MESSAGE="Migrating remote user settings"
    echo_stat
    sudo sed -i "/REMOTE_USER=''/c\REMOTE_USER='${REMOTE_USER}'" /etc/gravity-sync/gravity-sync.conf
    error_validate

    if [ "${LOCAL_PIHOLE_DIRECTORY}" == '' ] || [ "${LOCAL_PIHOLE_DIRECTORY}" == '/etc/pihole' ]; then
        MESSAGE="Defaulting local Pi-hole directory setting"
        echo_good_clean
    else
        MESSAGE="Migrating local Pi-hole directory setting"
        echo_stat
        sudo sed -i "/LOCAL_PIHOLE_DIRECTORY=''/c\LOCAL_PIHOLE_DIRECTORY='${LOCAL_PIHOLE_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    if [ "${REMOTE_PIHOLE_DIRECTORY}" == '' ] || [ "${REMOTE_PIHOLE_DIRECTORY}" == '/etc/pihole' ]; then
        MESSAGE="Defaulting remote Pi-hole directory setting"
        echo_good_clean
    else
        MESSAGE="Migrating remote Pi-hole directory setting"
        echo_stat
        sudo sed -i "/REMOTE_PIHOLE_DIRECTORY=''/c\REMOTE_PIHOLE_DIRECTORY='${REMOTE_PIHOLE_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    if [ "${LOCAL_DNSMASQ_DIRECTORY}" == '' ] || [ "${LOCAL_DNSMASQ_DIRECTORY}" == '/etc/dnsmasq.d' ]; then
        MESSAGE="Defaulting local DNSMASQ directory setting"
        echo_good_clean
    else
        MESSAGE="Migrating local DNSMASQ directory setting"
        echo_stat
        sudo sed -i "/LOCAL_DNSMASQ_DIRECTORY=''/c\LOCAL_DNSMASQ_DIRECTORY='${LOCAL_DNSMASQ_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    if [ "${REMOTE_DNSMASQ_DIRECTORY}" == '' ] || [ "${REMOTE_DNSMASQ_DIRECTORY}" == '/etc/dnsmasq.d' ]; then
        MESSAGE="Defaulting remote DNSMASQ directory setting"
        echo_good_clean
    else
        MESSAGE="Migrating remote DNSMASQ directory setting"
        echo_stat
        sudo sed -i "/REMOTE_DNSMASQ_DIRECTORY=''/c\REMOTE_DNSMASQ_DIRECTORY='${REMOTE_DNSMASQ_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    if [ "${LOCAL_FILE_OWNER}" == '' ]; then
        MESSAGE="Defaulting local file owner setting"
        echo_good_clean
    else
        MESSAGE="Migrating local file owner setting"
        echo_stat
        sudo sed -i "/LOCAL_FILE_OWNER=''/c\LOCAL_FILE_OWNER='${LOCAL_FILE_OWNER}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    if [ "${REMOTE_FILE_OWNER}" == '' ]; then
        MESSAGE="Defaulting remote file owner setting"
        echo_good_clean
    else
        MESSAGE="Migrating remote file owner setting"
        echo_stat
        sudo sed -i "/REMOTE_FILE_OWNER=''/c\REMOTE_FILE_OWNER='${REMOTE_FILE_OWNER}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    if [ "${LOCAL_DOCKER_CONTAINER}" == '' ] || [ "${LOCAL_DOCKER_CONTAINER}" == 'pihole' ]; then
        MESSAGE="Defaulting local Pi-hole container setting"
        echo_good_clean
    else
        MESSAGE="Migrating local Pi-hole container setting"
        echo_stat
        sudo sed -i "/LOCAL_DOCKER_CONTAINER=''/c\LOCAL_DOCKER_CONTAINER='${LOCAL_DOCKER_CONTAINER}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    if [ "${REMOTE_DOCKER_CONTAINER}" == '' ] || [ "${REMOTE_DOCKER_CONTAINER}" == 'pihole' ]; then
        MESSAGE="Defaulting remote Pi-hole container setting"
        echo_good_clean
    else
        MESSAGE="Migrating local Pi-hole container setting"
        echo_stat
        sudo sed -i "/REMOTE_DOCKER_CONTAINER=''/c\REMOTE_DOCKER_CONTAINER='${REMOTE_DOCKER_CONTAINER}'" /etc/gravity-sync/gravity-sync.conf
        error_validate
    fi

    MESSAGE="Migrating task history"
    echo_stat
    sudo cp logs/gravity-sync.log /etc/gravity-sync/gs-sync.log
    error_validate

    MESSAGE="Migrating hashing tables"
    echo_stat
    if [ -f "logs/gravity-sync.md5" ]; then
        REMOTE_DB_MD5=$(sed "1q;d" logs/gravity-sync.md5)
        LOCAL_DB_MD5=$(sed "2q;d" logs/gravity-sync.md5)
        REMOTE_CL_MD5=$(sed "3q;d" logs/gravity-sync.md5)
        LOCAL_CL_MD5=$(sed "4q;d" logs/gravity-sync.md5)
        REMOTE_CN_MD5=$(sed "5q;d" logs/gravity-sync.md5)
        LOCAL_CN_MD5=$(sed "6q;d" logs/gravity-sync.md5)
        
        echo -e ${REMOTE_DB_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_GRAVITY_FI_MD5_LOG} 1> /dev/null
        echo -e ${LOCAL_DB_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_GRAVITY_FI_MD5_LOG} 1> /dev/null
        echo -e ${REMOTE_CL_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CUSTOM_DNS_MD5_LOG} 1> /dev/null
        echo -e ${LOCAL_CL_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CUSTOM_DNS_MD5_LOG} 1> /dev/null
        echo -e ${REMOTE_CN_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CNAME_CONF_MD5_LOG} 1> /dev/null
        echo -e ${LOCAL_CN_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CNAME_CONF_MD5_LOG} 1> /dev/null
    else
        REMOTE_DB_MD5="0"
        LOCAL_DB_MD5="0"
        REMOTE_CL_MD5="0"
        LOCAL_CL_MD5="0"
        REMOTE_CN_MD5="0"
        LOCAL_CN_MD5="0"

        echo -e ${REMOTE_DB_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_GRAVITY_FI_MD5_LOG} 1> /dev/null
        echo -e ${LOCAL_DB_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_GRAVITY_FI_MD5_LOG} 1> /dev/null
        echo -e ${REMOTE_CL_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CUSTOM_DNS_MD5_LOG} 1> /dev/null
        echo -e ${LOCAL_CL_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CUSTOM_DNS_MD5_LOG} 1> /dev/null
        echo -e ${REMOTE_CN_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CNAME_CONF_MD5_LOG} 1> /dev/null
        echo -e ${LOCAL_CN_MD5} | sudo tee -a ${GS_ETC_PATH}/${GS_CNAME_CONF_MD5_LOG} 1> /dev/null
    fi
    error_validate
}

function remove_old_version {
    MESSAGE="Removing Old Version & Settings"
    echo_info

    if hash crontab 2>/dev/null; then
        MESSAGE="Clearing automation from crontab"
        echo_stat
            crontab -l > cronjob-old.tmp
            sed "/gravity-sync.sh/d" cronjob-old.tmp > cronjob-new.tmp
            crontab cronjob-new.tmp
        error_validate
    fi

    kill_automation_service

    if [ -f /etc/bash.bashrc ]; then
         MESSAGE="Cleaning up bash.bashrc"
         echo_info
         sudo sed -i "/gravity-sync.sh/d" /etc/bash.bashrc
         error_validate
    fi

    MESSAGE="Removing old Gravity Sync folder"
    echo_stat
    sudo rm -fr ${LOCAL_FOLDR}
    error_validate
}

function kill_automation_service {
    if systemctl is-active --quiet gravity-sync; then
        MESSAGE="Stopping ${PROGRAM} timer"
        echo_stat
        sudo systemctl stop gravity-sync
        error_validate

        MESSAGE="Disabling ${PROGRAM} automation service"
        echo_stat
        sudo systemctl disable gravity-sync --quiet
        error_validate

        MESSAGE="Removing systemd timer"
        echo_stat
        sudo rm -f ${OS_DAEMON_PATH}/gravity-sync.timer
        error_validate

        MESSAGE="Removing systemd service"
        echo_stat
        sudo rm -f ${OS_DAEMON_PATH}/gravity-sync.service
        error_validate

        MESSAGE="Reloading systemd daemon"
        echo_stat
        sudo systemctl daemon-reload --quiet
        error_validate
    fi
}

function end_migration {
    MESSAGE="Migration Complete"
    echo_info


}

# SCRIPT EXECUTION ###########################

case $# in
    0)
        start_gs_no_config
        check_old_version
        install_new_gravity
        upgrade_to_4 
        remove_old_version 
        end_migration ;;
    1)
        case $1 in
            *)
                start_gs_no_config
                check_old_version
                install_new_gravity
                upgrade_to_4 
                remove_old_version
                end_migration ;;
        esac
    ;;
    
    *)
        start_gs_no_config
        check_old_version
        install_new_gravity
        upgrade_to_4 
        remove_old_version
        end_migration ;;
esac

# END OF SCRIPT ##############################
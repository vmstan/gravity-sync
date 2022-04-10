#!/usr/bin/env bash

# GRAVITY SYNC BY VMSTAN #####################
# GS 3.x to 4.0 Upgrade Utility ##############

# Run only to upgrade your existing Gravity Sync 3.x installation to 4.0 format

GS_FILEPATH=$(realpath $0)
LOCAL_FOLDR=$(dirname $GS_FILEPATH)

function check_old_version {
    echo -e "Checker"

    if [ -f settings/gravity-sync.conf ]; then
        echo -e "Old configuration detected"
    else
        echo -e "No old config detected"
        exit
    fi

}

function install_new_gravity {
    echo -e "Installer"

    if [ -d /etc/gravity-sync/.gs ]; then
        sudo rm -fr /etc/gravity-sync/.gs
    fi

    if [ ! -d /etc/gravity-sync ]; then
        sudo mkdir /etc/gravity-sync
        sudo chmod 775 /etc/gravity-sync
    fi

    if [ -f /usr/local/bin/gravity-sync ]; then
        sudo rm -f /usr/local/bin/gravity-sync
    fi
    
    # change to master before final release
    sudo git clone -b "4.0.0" https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
    sudo touch /etc/gravity-sync/.gs/dev
    echo -e "origin/4.0.0" | sudo tee /etc/gravity-sync/.gs/dev

    sudo cp /etc/gravity-sync/.gs/gravity-sync /usr/local/bin
}

function upgrade_to_4 {
    echo -e "Upgrader"
    
    sudo cp $HOME/.ssh/id_rsa /etc/gravity-sync/gravity-sync.rsa
    sudo cp $HOME/.ssh/id_rsa.pub /etc/gravity-sync/gravity-sync.rsa.pub

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

    source settings/gravity-sync.conf
    sudo cp /etc/gravity-sync/.gs/gravity-sync/templates/gravity-sync.conf.example /etc/gravity-sync/gravity-sync.conf
    sudo cp logs/gravity-sync.log /etc/gravity-sync/gravity-sync.log

    LOCAL_PIHOLE_DIRECTORY=${PIHOLE_DIR}
    REMOTE_PIHOLE_DIRECTORY=${RIHOLE_DIR}
    LOCAL_DNSMASQ_DIRECTORY=${DNSMAQ_DIR}
    REMOTE_DNSMASQ_DIRECTORY=${RNSMAQ_DIR}
    LOCAL_FILE_OWNER=${FILE_OWNER}
    REMOTE_FILE_OWNER=${RILE_OWNER}
    LOCAL_DOCKER_CONTAINER=${DOCKER_CON}
    REMOTE_DOCKER_CONTAINER=${ROCKER_CON}

    sudo sed -i "/REMOTE_HOST=''/c\REMOTE_HOST='${REMOTE_HOST}'" /etc/gravity-sync/gravity-sync.conf
    sudo sed -i "/REMOTE_USER=''/c\REMOTE_HOST='${REMOTE_USER}'" /etc/gravity-sync/gravity-sync.conf

    if [ "${LOCAL_PIHOLE_DIRECTORY}" == '' ] || [ "${LOCAL_PIHOLE_DIRECTORY}" == '/etc/pihole' ]; then
        SKIP="1"
    else
        sudo sed -i "/LOCAL_PIHOLE_DIRECTORY=''/c\LOCAL_PIHOLE_DIRECTORY='${LOCAL_PIHOLE_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
    fi

    if [ "${REMOTE_PIHOLE_DIRECTORY}" == '' ] || [ "${REMOTE_PIHOLE_DIRECTORY}" == '/etc/pihole' ]; then
        SKIP="1"
    else
        sudo sed -i "/REMOTE_PIHOLE_DIRECTORY=''/c\REMOTE_PIHOLE_DIRECTORY='${REMOTE_PIHOLE_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
    fi

    if [ "${LOCAL_DNSMASQ_DIRECTORY}" == '' ] || [ "${LOCAL_DNSMASQ_DIRECTORY}" == '/etc/dnsmasq.d' ]; then
        SKIP="1"
    else
        sudo sed -i "/LOCAL_DNSMASQ_DIRECTORY=''/c\LOCAL_DNSMASQ_DIRECTORY='${LOCAL_DNSMASQ_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
    fi

    if [ "${REMOTE_DNSMASQ_DIRECTORY}" == '' ] || [ "${REMOTE_DNSMASQ_DIRECTORY}" == '/etc/dnsmasq.d' ]; then
        SKIP="1"
    else
        sudo sed -i "/REMOTE_DNSMASQ_DIRECTORY=''/c\REMOTE_DNSMASQ_DIRECTORY='${REMOTE_DNSMASQ_DIRECTORY}'" /etc/gravity-sync/gravity-sync.conf
    fi

    if [ "${LOCAL_FILE_OWNER}" == '' ]; then
        sudo sed -i "/LOCAL_FILE_OWNER=''/c\LOCAL_FILE_OWNER='${LOCAL_FILE_OWNER}'" /etc/gravity-sync/gravity-sync.conf
    fi

    if [ "${REMOTE_FILE_OWNER}" == '' ]; then
        SKIP="1"
    else
        sudo sed -i "/REMOTE_FILE_OWNER=''/c\REMOTE_FILE_OWNER='${REMOTE_FILE_OWNER}'" /etc/gravity-sync/gravity-sync.conf
    fi

    if [ "${LOCAL_DOCKER_CONTAINER}" == '' ] || [ "${LOCAL_DOCKER_CONTAINER}" == 'pihole' ]; then
        SKIP="1"
    else
        sudo sed -i "/LOCAL_DOCKER_CONTAINER=''/c\LOCAL_DOCKER_CONTAINER='${LOCAL_DOCKER_CONTAINER}'" /etc/gravity-sync/gravity-sync.conf
    fi

    if [ "${REMOTE_DOCKER_CONTAINER}" == '' ] || [ "${REMOTE_DOCKER_CONTAINER}" == 'pihole' ]; then
        SKIP="1"
    else
        sudo sed -i "/REMOTE_DOCKER_CONTAINER=''/c\REMOTE_DOCKER_CONTAINER='${REMOTE_DOCKER_CONTAINER}'" /etc/gravity-sync/gravity-sync.conf
    fi

    echo -e "${SKIP}"
}

function remove_old_version {
    echo -e "Remover"

    crontab -l > cronjob-old.tmp
    sed "/gravity-sync.sh/d" cronjob-old.tmp > cronjob-new.tmp
    crontab cronjob-new.tmp

    sudo rm -fr ${LOCAL_FOLDR}
}

# SCRIPT EXECUTION ###########################

case $# in
    0)
        check_old_version
        install_new_gravity
        upgrade_to_4 
        remove_old_version ;;
    1)
        case $1 in
            *)
                check_old_version
                install_new_gravity
                upgrade_to_4 
                remove_old_version ;;
        esac
    ;;
    
    *)
        check_old_version
        install_new_gravity
        upgrade_to_4 
        remove_old_version ;;
esac

# END OF SCRIPT ##############################
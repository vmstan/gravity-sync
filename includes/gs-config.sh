# GRAVITY SYNC BY VMSTAN #####################
# gs-config.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Configure Task
function task_configure {				
    TASKTYPE='CONFIGURE'
    MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
    echo_good
    
    if [ -f ${LOCAL_FOLDR}/${CONFIG_FILE} ]
    then		
        config_delete
    else
        config_generate
    fi

    # backup_settime
    # backup_local_gravity
    # backup_local_custom
    # backup_cleanup
    
    create_alias
    
    exit_withchange
}

## Generate New Configuration
function config_generate {
    # detect_ssh
    
    MESSAGE="Creating New ${CONFIG_FILE} from Template"
    echo_stat
    cp ${LOCAL_FOLDR}/${CONFIG_FILE}.example ${LOCAL_FOLDR}/${CONFIG_FILE}
    error_validate
    
    docker_detect
    if [ "${DOCKERREADY}" == "1" ]
    then
        MESSAGE="Advanced Configuration Required"
        echo_info
        advanced_config_generate
    else
        MESSAGE="Use Advanced Installation Options? (Leave blank for default 'No')"
        echo_need
        read INPUT_ADVANCED_INSTALL
        INPUT_ADVANCED_INSTALL="${INPUT_ADVANCED_INSTALL:-N}"
    
        if [ "${INPUT_ADVANCED_INSTALL}" != "N" ]
        then
            MESSAGE="Advanced Configuration Selected"
            echo_info
        
            advanced_config_generate
        fi
    fi
    
    MESSAGE="Standard Settings"
    echo_info

    MESSAGE="Primary Pi-hole Address (IP or DNS)"
    echo_need
    read INPUT_REMOTE_HOST

    if [ "${PING_AVOID}" != "1" ]
    then
        MESSAGE="Testing Network Connection (ICMP)"
        echo_stat
        ping -c 3 ${INPUT_REMOTE_HOST} >/dev/null 2>&1
            error_validate
    else
        MESSAGE="Bypassing Network Testing (ICMP)"
        echo_warn
    fi
    
    MESSAGE="SSH User for ${INPUT_REMOTE_HOST}"
    echo_need
    read INPUT_REMOTE_USER
    
    MESSAGE="Saving Host to ${CONFIG_FILE}"
    echo_stat
    sed -i "/REMOTE_HOST='192.168.1.10'/c\REMOTE_HOST='${INPUT_REMOTE_HOST}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
    error_validate
    
    MESSAGE="Saving User to ${CONFIG_FILE}"
    echo_stat
    sed -i "/REMOTE_USER='pi'/c\REMOTE_USER='${INPUT_REMOTE_USER}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
    error_validate

    generate_sshkey
    
    MESSAGE="Importing New ${CONFIG_FILE}"
    echo_stat
    source ${LOCAL_FOLDR}/${CONFIG_FILE}
    error_validate

    export_sshkey	
    
    # MESSAGE="Testing Configuration"
    # echo_info

    # validate_os_sshpass
    # validate_sqlite3

    # detect_remotersync
}

## Advanced Configuration Options
function advanced_config_generate {
    MESSAGE="Local Pi-hole in Docker Container? (Leave blank for default 'No')"
    echo_need
    read INPUT_PH_IN_TYPE
    INPUT_PH_IN_TYPE="${INPUT_PH_IN_TYPE:-N}"
    
    if [ "${INPUT_PH_IN_TYPE}" != "N" ]
    then
        MESSAGE="Saving Local Docker Setting to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# PH_IN_TYPE=''/c\PH_IN_TYPE='docker'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
        
        MESSAGE="Local Docker Container Name? (Leave blank for default 'pihole')"
        echo_need
        read INPUT_DOCKER_CON
        INPUT_DOCKER_CON="${INPUT_DOCKER_CON:-pihole}"
        
        if [ "${INPUT_DOCKER_CON}" != "pihole" ]
        then
            MESSAGE="Saving Local Container Name to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DOCKER_CON=''/c\DOCKER_CON='${INPUT_DOCKER_CON}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
        fi
        
        MESSAGE="Local Pi-hole 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_PIHOLE_DIR
        
        if [ "${INPUT_PIHOLE_DIR}" != "" ]
        then
            MESSAGE="Saving Local Pi-hole Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# PIHOLE_DIR=''/c\PIHOLE_DIR='${INPUT_PIHOLE_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
            SKIP_PIHOLE_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Local DNSMASQ 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_DNSMAQ_DIR
        
        if [ "${INPUT_DNSMAQ_DIR}" != "" ]
        then
            MESSAGE="Saving Local DNSMASQ Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DNSMAQ_DIR=''/c\DNSMAQ_DIR='${INPUT_DNSMAQ_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
            SKIP_DNSMAQ_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Saving Local Volume Ownership to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# FILE_OWNER=''/c\FILE_OWNER='999:999'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
    fi
    
    MESSAGE="Remote Pi-hole in Docker Container? (Leave blank for default 'No')"
    echo_need
    read INPUT_RH_IN_TYPE
    INPUT_RH_IN_TYPE="${INPUT_RH_IN_TYPE:-N}"
    
    if [ "${INPUT_RH_IN_TYPE}" != "N" ]
    then
        MESSAGE="Saving Remote Docker Setting to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# RH_IN_TYPE=''/c\RH_IN_TYPE='docker'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
        
        MESSAGE="Remote Docker Container Name? (Leave blank for default 'pihole')"
        echo_need
        read INPUT_ROCKER_CON
        INPUT_ROCKER_CON="${INPUT_ROCKER_CON:-pihole}"
        
        if [ "${INPUT_ROCKER_CON}" != "pihole" ]
        then
            MESSAGE="Saving Remote Container Name to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# ROCKER_CON=''/c\ROCKER_CON='${INPUT_ROCKER_CON}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
        fi
        
        MESSAGE="Remote Pi-hole 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_RIHOLE_DIR
        
        if [ "${INPUT_RIHOLE_DIR}" != "" ]
        then
            MESSAGE="Saving Remote Pi-hole Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RIHOLE_DIR=''/c\RIHOLE_DIR='${INPUT_RIHOLE_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
            SKIP_RIHOLE_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Remote DNSMASQ 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_RNSMAQ_DIR
        
        if [ "${INPUT_RNSMAQ_DIR}" != "" ]
        then
            MESSAGE="Saving Remote DNSMASQ Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RNSMAQ_DIR=''/c\RNSMAQ_DIR='${INPUT_RNSMAQ_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
            SKIP_RNSMAQ_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Saving Remote Volume Ownership to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# RILE_OWNER=''/c\RILE_OWNER='999:999'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
    fi
    
        
    if [ "$SKIP_PIHOLE_DIR" != "1" ]
    then
        MESSAGE="Local Pi-hole Settings Directory Path? (Leave blank for default '/etc/pihole')"
        echo_need
        read INPUT_PIHOLE_DIR
        INPUT_PIHOLE_DIR="${INPUT_PIHOLE_DIR:-/etc/pihole}"
        
        if [ "${INPUT_PIHOLE_DIR}" != "/etc/pihole" ]
        then
            MESSAGE="Saving Local Pi-hole Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# PIHOLE_DIR=''/c\PIHOLE_DIR='${INPUT_PIHOLE_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_RIHOLE_DIR" != "1" ]
    then
        MESSAGE="Remote Pi-hole Settings Directory Path? (Leave blank for default '/etc/pihole')"
        echo_need
        read INPUT_RIHOLE_DIR
        INPUT_RIHOLE_DIR="${INPUT_RIHOLE_DIR:-/etc/pihole}"
        
        if [ "${INPUT_RIHOLE_DIR}" != "/etc/pihole" ]
        then
            MESSAGE="Saving Remote Pi-hole Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RIHOLE_DIR=''/c\RIHOLE_DIR='${INPUT_RIHOLE_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_DNSMASQ_DIR" != "1" ]
    then
        MESSAGE="Local DNSMASQ Settings Directory Path? (Leave blank for default '/etc/dnsmasq.d')"
        echo_need
        read INPUT_DNSMASQ_DIR
        INPUT_DNSMASQ_DIR="${INPUT_DNSMASQ_DIR:-/etc/dnsmasq.d}"
        
        if [ "${INPUT_DNSMASQ_DIR}" != "/etc/dnsmasq.d" ]
        then
            MESSAGE="Saving Local DNSMASQ Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DNSMASQ_DIR=''/c\DNSMASQ_DIR='${INPUT_DNSMASQ_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_RNSMASQ_DIR" != "1" ]
    then
        MESSAGE="Remote DNSMASQ Settings Directory Path? (Leave blank for default '/etc/dnsmasq.d')"
        echo_need
        read INPUT_RNSMASQ_DIR
        INPUT_RNSMASQ_DIR="${INPUT_RNSMASQ_DIR:-/etc/dnsmasq.d}"
        
        if [ "${INPUT_RNSMASQ_DIR}" != "/etc/dnsmasq.d" ]
        then
            MESSAGE="Saving Remote DNSMASQ Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RNSMASQ_DIR=''/c\RNSMASQ_DIR='${INPUT_RNSMASQ_DIR}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    MESSAGE="Use Custom SSH Port? (Leave blank for default '22')"
    echo_need
    read INPUT_SSH_PORT
    INPUT_SSH_PORT="${INPUT_SSH_PORT:-22}"
    SSH_PORT="${INPUT_SSH_PORT}"
    
    if [ "${INPUT_SSH_PORT}" != "22" ]
    then
        MESSAGE="Saving Custom SSH Port to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# SSH_PORT=''/c\SSH_PORT='${INPUT_SSH_PORT}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
    fi
    
    MESSAGE="Enable ICMP Check? (Leave blank for default 'Yes')"
    echo_need
    read INPUT_PING_AVOID
    INPUT_PING_AVOID="${INPUT_PING_AVOID:-Y}"
    
    if [ "${INPUT_PING_AVOID}" != "Y" ]
    then
        MESSAGE="Saving ICMP Avoidance to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# PING_AVOID=''/c\PING_AVOID='1'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
        PING_AVOID=1
    fi
        
    MESSAGE="Use Custom SSH PKIF Location? (Leave blank for default '.ssh/id_rsa')"
    echo_need
    read INPUT_CUSTOM_PKIF
    INPUT_CUSTOM_PKIF="${INPUT_CUSTOM_PKIF:-.ssh/id_rsa}"
        
    if [ "${INPUT_CUSTOM_PKIF}" != ".ssh/id_rsa" ]
    then
        MESSAGE="Saving Custom PKIF to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# SSH_PKIF=''/c\SSH_PKIF='${INPUT_CUSTOM_PKIF}'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
    fi
    
    MESSAGE="Enable Replicate 'Local DNS Records' Feature? (Leave blank for default 'Yes')"
    echo_need
    read INPUT_SKIP_CUSTOM
    INPUT_SKIP_CUSTOM="${INPUT_SKIP_CUSTOM:-Y}"
    
    if [ "${INPUT_SKIP_CUSTOM}" != "Y" ]
    then
        MESSAGE="Saving Local DNS Preference to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# SKIP_CUSTOM=''/c\SKIP_CUSTOM='1'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
    fi
    
    if [ "${INPUT_SKIP_CUSTOM}" == "Y" ]
    then
        MESSAGE="Enable Replicate 'Local CNAME Records' Feature? (Leave blank for default 'Yes')"
        echo_need
        read INPUT_INCLUDE_CNAME
        INPUT_INCLUDE_CNAME="${INPUT_INCLUDE_CNAME:-Y}"
        
        if [ "${INPUT_INCLUDE_CNAME}" == "Y" ]
        then
            MESSAGE="Saving Local CNAME Preference to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# INCLUDE_CNAME=''/c\INCLUDE_CNAME='1'" ${LOCAL_FOLDR}/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    MESSAGE="Change Backup Retention in Days? (Leave blank for default '7')"
    echo_need
    read INPUT_BACKUP_RETAIN
    INPUT_BACKUP_RETAIN="${INPUT_BACKUP_RETAIN:-7}"
    
    if [ "${INPUT_BACKUP_RETAIN}" != "7" ]
    then
        MESSAGE="Saving Backup Retention to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# BACKUP_RETAIN=''/c\BACKUP_RETAIN='1'" ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate
    fi
}

## Delete Existing Configuration
function config_delete {
    source ${LOCAL_FOLDR}/${CONFIG_FILE}
    MESSAGE="Configuration File Exists"
    echo_warn
    
    echo_lines
    cat ${LOCAL_FOLDR}/${CONFIG_FILE}
    echo_lines
    
    MESSAGE="Are you sure you want to erase this configuration?"
    echo_warn

    intent_validate

    MESSAGE="Erasing Existing Configuration"
    echo_stat
    rm -f ${LOCAL_FOLDR}/${CONFIG_FILE}
        error_validate

    config_generate
}

## Detect Docker
function docker_detect {
    if hash docker 2>/dev/null
    then
        FTLCHECK=$(sudo docker container ls | grep 'pihole/pihole')
        if [ "$FTLCHECK" != "" ]
        then
            DOCKERREADY="1"
        fi
    fi
}

## Create Bash Alias
function create_alias {
    MESSAGE="Creating Bash Alias"
    echo_stat
    
    echo -e "alias gravity-sync='${GS_FILEPATH}'" | sudo tee -a /etc/bash.bashrc > /dev/null
        error_validate
}

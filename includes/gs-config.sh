# GRAVITY SYNC BY VMSTAN #####################
# gs-config.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Configure Task
function task_configure {				
    TASKTYPE='CONFIGURE'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    relocate_config_gs
    
    if [ -f ${LOCAL_FOLDR}/settings/${CONFIG_FILE} ]
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
    cp ${LOCAL_FOLDR}/templates/${CONFIG_FILE}.example ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    error_validate
    
    echo_lines
    echo -e "Welcome to the ${PURPLE}Gravity Sync${NC} Configuration Wizard"
    echo -e "Please read through ${BLUE}https://github.com/vmstan/gravity-sync/wiki${NC} before you continue!"
    echo_blank
    echo -e "If the installer detects that you have a supported container engine (Docker or Podman) installed,"
    echo -e "you will be directed to the advanced installation options. Otherwise you can manually enable this" 
    echo -e "to adjust settings such as custom Pi-hole binary or configuration directories, SSH options, CNAME"
    echo -e "replication, and backup retention."
    echo_blank
    echo -e "Gravity Sync uses a primary/secondary model for replication, and normally syncs changes from the "
    echo -e "primary to the secondary. The LOCAL Pi-hole where you are running this configuration script is"
    echo -e "considered the the SECONDARY Pi-hole! The REMOTE Pi-hole where you will normally make configuration" 
    echo -e "changes is considered the PRIMARY Pi-hole."
    echo_blank
    echo -e "Confused? Please refer back to the documentation."
    echo_lines
    
    docker_detect
    podman_detect
    
    if [ "${DOCKERREADY}" == "1" ] || [ "${PODMANREADY}" == "1" ]
    then
        MESSAGE="Container Engine Detected"
        echo_good
        MESSAGE="Advanced Configuration Required"
        echo_info
        advanced_config_generate
    else
        MESSAGE="Use Advanced Installation Options? (Y/N, default N)"
        echo_need
        read INPUT_ADVANCED_INSTALL
        INPUT_ADVANCED_INSTALL="${INPUT_ADVANCED_INSTALL:-N}"
    
        if [ "${INPUT_ADVANCED_INSTALL}" == "Y" ]
        then
            MESSAGE="Advanced Configuration Selected"
            echo_info
        
            advanced_config_generate
        elif [ "${INPUT_ADVANCED_INSTALL}" == "N" ]
        then
            MESSAGE="Standard Configuration Selected"
            echo_info
        else
            MESSAGE="Invalid Selection"
            echo_warn
            
            exit_nochange
        fi
    fi
    
    MESSAGE="Required Gravity Sync Settings"
    echo_info

    MESSAGE="Primary/Remote Pi-hole Address (IP or DNS)"
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
    
    MESSAGE="Saving Primary/Remote Host to ${CONFIG_FILE}"
    echo_stat
    sed -i "/REMOTE_HOST='192.168.1.10'/c\REMOTE_HOST='${INPUT_REMOTE_HOST}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    error_validate
    
    MESSAGE="Existing SSH User for ${INPUT_REMOTE_HOST}"
    echo_need
    read INPUT_REMOTE_USER
    
    MESSAGE="Saving User "${INPUT_REMOTE_USER}" to ${CONFIG_FILE}"
    echo_stat
    sed -i "/REMOTE_USER='pi'/c\REMOTE_USER='${INPUT_REMOTE_USER}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    error_validate

    generate_sshkey
    
    MESSAGE="Importing New ${CONFIG_FILE}"
    echo_stat
    source ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
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
    MESSAGE="Local/Secondary Pi-hole Instance Type? (Allowed: 'docker' or 'podman' or 'default')"
    echo_need
    read INPUT_PH_IN_TYPE
    INPUT_PH_IN_TYPE="${INPUT_PH_IN_TYPE:-default}"
    
    if [ "${INPUT_PH_IN_TYPE}" != "default" ]
    then
        if [ "${INPUT_PH_IN_TYPE}" != "docker" ] && [ "${INPUT_PH_IN_TYPE}" != "podman" ]
        then
            MESSAGE="Local/Secondary Container Type must either be 'docker' or 'podman'"
            echo_warn
            exit_withchanges
        fi

        MESSAGE="Saving Local/Secondary Container Type Setting to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# PH_IN_TYPE=''/c\PH_IN_TYPE='${INPUT_PH_IN_TYPE}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
        
        
        MESSAGE="Displaying Currently Running Container Images"
        echo_info
        
        echo_lines
        if [ "${INPUT_PH_IN_TYPE}" == "docker" ] 
        then
            sudo docker container ls
        elif [ "${INPUT_PH_IN_TYPE}" == "podman" ]
        then
            sudo podman container ls
        fi
        echo_lines
        
        MESSAGE="Local/Secondary Container Name? (Leave blank for default 'pihole')"
        echo_need
        read INPUT_DOCKER_CON
        INPUT_DOCKER_CON="${INPUT_DOCKER_CON:-pihole}"
        
        if [ "${INPUT_DOCKER_CON}" != "pihole" ]
        then
            MESSAGE="Saving Local/Secondary Container Name to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DOCKER_CON=''/c\DOCKER_CON='${INPUT_DOCKER_CON}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
        
        MESSAGE="Local/Secondary Pi-hole 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_PIHOLE_DIR
        
        if [ "${INPUT_PIHOLE_DIR}" != "" ]
        then
            MESSAGE="Saving Local/Secondary Pi-hole Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# PIHOLE_DIR=''/c\PIHOLE_DIR='${INPUT_PIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
            SKIP_PIHOLE_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Local/Secondary DNSMASQ 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_DNSMAQ_DIR
        
        if [ "${INPUT_DNSMAQ_DIR}" != "" ]
        then
            MESSAGE="Saving Local/Secondary DNSMASQ Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DNSMAQ_DIR=''/c\DNSMAQ_DIR='${INPUT_DNSMAQ_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
            SKIP_DNSMASQ_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Saving Local/Secondary Volume Ownership to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# FILE_OWNER=''/c\FILE_OWNER='999:999'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
    MESSAGE="Primary/Remote Pi-hole Instance Type? (Allowed: 'docker' or 'podman' or 'default')"
    echo_need
    read INPUT_RH_IN_TYPE
    INPUT_RH_IN_TYPE="${INPUT_RH_IN_TYPE:-default}"
    
    if [ "${INPUT_RH_IN_TYPE}" != "default" ]
    then
        if [ "${INPUT_RH_IN_TYPE}" != "docker" ] && [ "${INPUT_RH_IN_TYPE}" != "podman" ]
        then
            MESSAGE="Primary/Remote Container Type must either be 'docker' or 'podman'"
            echo_warn
            exit_withchanges
        fi
        MESSAGE="Saving Primary/Remote Container Type Setting to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# RH_IN_TYPE=''/c\RH_IN_TYPE='${INPUT_RH_IN_TYPE}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
        
        MESSAGE="Primary/Remote Container Name? (Leave blank for default 'pihole')"
        echo_need
        read INPUT_ROCKER_CON
        INPUT_ROCKER_CON="${INPUT_ROCKER_CON:-pihole}"
        
        if [ "${INPUT_ROCKER_CON}" != "pihole" ]
        then
            MESSAGE="Saving Primary/Remote Container Name to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# ROCKER_CON=''/c\ROCKER_CON='${INPUT_ROCKER_CON}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
        
        MESSAGE="Primary/Remote Pi-hole 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_RIHOLE_DIR
        
        if [ "${INPUT_RIHOLE_DIR}" != "" ]
        then
            MESSAGE="Saving Primary/Remote Pi-hole Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RIHOLE_DIR=''/c\RIHOLE_DIR='${INPUT_RIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
            SKIP_RIHOLE_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Primary/Remote DNSMASQ 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_RNSMAQ_DIR
        
        if [ "${INPUT_RNSMAQ_DIR}" != "" ]
        then
            MESSAGE="Saving Primary/Remote DNSMASQ Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RNSMAQ_DIR=''/c\RNSMAQ_DIR='${INPUT_RNSMAQ_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
            SKIP_RNSMASQ_DIR="1"
        else
            MESSAGE="This setting is required!"
            echo_warn
            exit_withchanges
        fi
        
        MESSAGE="Saving Primary/Remote Volume Ownership to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# RILE_OWNER=''/c\RILE_OWNER='999:999'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
        
    if [ "$SKIP_PIHOLE_DIR" != "1" ]
    then
        MESSAGE="Local/Secondary Pi-hole Settings Directory Path? (Leave blank for default '/etc/pihole')"
        echo_need
        read INPUT_PIHOLE_DIR
        INPUT_PIHOLE_DIR="${INPUT_PIHOLE_DIR:-/etc/pihole}"
        
        if [ "${INPUT_PIHOLE_DIR}" != "/etc/pihole" ]
        then
            MESSAGE="Saving Local/Secondary Pi-hole Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# PIHOLE_DIR=''/c\PIHOLE_DIR='${INPUT_PIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_RIHOLE_DIR" != "1" ]
    then
        MESSAGE="Primary/Remote Pi-hole Settings Directory Path? (Leave blank for default '/etc/pihole')"
        echo_need
        read INPUT_RIHOLE_DIR
        INPUT_RIHOLE_DIR="${INPUT_RIHOLE_DIR:-/etc/pihole}"
        
        if [ "${INPUT_RIHOLE_DIR}" != "/etc/pihole" ]
        then
            MESSAGE="Saving Primary/Remote Pi-hole Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RIHOLE_DIR=''/c\RIHOLE_DIR='${INPUT_RIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_DNSMASQ_DIR" != "1" ]
    then
        MESSAGE="Local/Secondary DNSMASQ Settings Directory Path? (Leave blank for default '/etc/dnsmasq.d')"
        echo_need
        read INPUT_DNSMASQ_DIR
        INPUT_DNSMASQ_DIR="${INPUT_DNSMASQ_DIR:-/etc/dnsmasq.d}"
        
        if [ "${INPUT_DNSMASQ_DIR}" != "/etc/dnsmasq.d" ]
        then
            MESSAGE="Saving Local/Secondary DNSMASQ Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DNSMASQ_DIR=''/c\DNSMASQ_DIR='${INPUT_DNSMASQ_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_RNSMASQ_DIR" != "1" ]
    then
        MESSAGE="Primary/Remote DNSMASQ Settings Directory Path? (Leave blank for default '/etc/dnsmasq.d')"
        echo_need
        read INPUT_RNSMASQ_DIR
        INPUT_RNSMASQ_DIR="${INPUT_RNSMASQ_DIR:-/etc/dnsmasq.d}"
        
        if [ "${INPUT_RNSMASQ_DIR}" != "/etc/dnsmasq.d" ]
        then
            MESSAGE="Saving Primary/Remote DNSMASQ Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RNSMASQ_DIR=''/c\RNSMASQ_DIR='${INPUT_RNSMASQ_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    MESSAGE="Custom SSH Port to Connect to Primary/Remote host? (Leave blank for default '22')"
    echo_need
    read INPUT_SSH_PORT
    INPUT_SSH_PORT="${INPUT_SSH_PORT:-22}"
    SSH_PORT="${INPUT_SSH_PORT}"
    
    if [ "${INPUT_SSH_PORT}" != "22" ]
    then
        MESSAGE="Saving Custom SSH Port to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# SSH_PORT=''/c\SSH_PORT='${INPUT_SSH_PORT}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
    MESSAGE="Enable Ping/ICMP Check of Primary/Remote? (Y/N, default 'Y')"
    echo_need
    read INPUT_PING_AVOID
    INPUT_PING_AVOID="${INPUT_PING_AVOID:-Y}"
    
    if [ "${INPUT_PING_AVOID}" != "Y" ]
    then
        MESSAGE="Saving ICMP Avoidance to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# PING_AVOID=''/c\PING_AVOID='1'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
        PING_AVOID=1
    fi
        
    MESSAGE="Custom SSH PKIF Location? (Leave blank for default '.ssh/id_rsa')"
    echo_need
    read INPUT_CUSTOM_PKIF
    INPUT_CUSTOM_PKIF="${INPUT_CUSTOM_PKIF:-.ssh/id_rsa}"
        
    if [ "${INPUT_CUSTOM_PKIF}" != ".ssh/id_rsa" ]
    then
        MESSAGE="Saving Custom PKIF to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# SSH_PKIF=''/c\SSH_PKIF='${INPUT_CUSTOM_PKIF}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
    MESSAGE="Enable Replicate 'Local DNS Records' Feature? (Y/N, default 'Y')"
    echo_need
    read INPUT_SKIP_CUSTOM
    INPUT_SKIP_CUSTOM="${INPUT_SKIP_CUSTOM:-Y}"
    
    if [ "${INPUT_SKIP_CUSTOM}" != "Y" ]
    then
        MESSAGE="Saving Local DNS Preference to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# SKIP_CUSTOM=''/c\SKIP_CUSTOM='1'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
    if [ "${INPUT_SKIP_CUSTOM}" == "Y" ]
    then
        MESSAGE="Enable Replicate 'Local CNAME Records' Feature? (Y/N, default 'Y')"
        echo_need
        read INPUT_INCLUDE_CNAME
        INPUT_INCLUDE_CNAME="${INPUT_INCLUDE_CNAME:-Y}"
        
        if [ "${INPUT_INCLUDE_CNAME}" == "Y" ]
        then
            MESSAGE="Saving Local CNAME Preference to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# INCLUDE_CNAME=''/c\INCLUDE_CNAME='1'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    MESSAGE="Change Backup Retention in Days? (Leave blank for default '3')"
    echo_need
    read INPUT_BACKUP_RETAIN
    INPUT_BACKUP_RETAIN="${INPUT_BACKUP_RETAIN:-3}"
    
    if [ "${INPUT_BACKUP_RETAIN}" != "3" ]
    then
        MESSAGE="Saving Backup Retention to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# BACKUP_RETAIN=''/c\BACKUP_RETAIN='${INPUT_BACKUP_RETAIN}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
}

## Delete Existing Configuration
function config_delete {
    source ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    MESSAGE="Configuration File Exists"
    echo_warn
    
    echo_lines
    cat ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    echo_blank
    echo_lines
    
    MESSAGE="Are you sure you want to erase this configuration?"
    echo_warn

    intent_validate

    MESSAGE="Erasing Existing Configuration"
    echo_stat
    rm -f ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
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

## Detect Podman
function podman_detect {
    if hash podman 2>/dev/null
    then
        FTLCHECK=$(sudo podman container ls | grep 'pihole/pihole')
        if [ "$FTLCHECK" != "" ]
        then
            PODMANREADY="1"
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

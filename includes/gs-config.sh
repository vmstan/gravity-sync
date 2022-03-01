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
    
    create_alias
    exit_withchange
}

## Generate New Configuration
function config_generate {  
    MESSAGE="${UI_CONFIG_CREATING} ${CONFIG_FILE}"
    echo_stat
    cp ${LOCAL_FOLDR}/templates/${CONFIG_FILE}.example ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    error_validate
    
    echo_lines
    echo -e "Welcome to the ${PURPLE}Gravity Sync${NC} Configuration Wizard"
    echo -e "Please read through ${BLUE}https://github.com/vmstan/gravity-sync/wiki${NC} before you continue!"
    echo_blank
    echo -e "If the installer detects that you have a supported container engine (Docker or Podman) installed"
    echo -e "on your local Pi-hole, you will be directed to the advanced installation options. If you using " 
    echo -e "containers on your remote Pi-hole, you'll need to select this option manually to adjust settings"
    echo -e "such as custom Pi-hole binary or configuration directories, CNAME replication, etc."
    echo_blank
    echo -e "Gravity Sync uses a primary/secondary model for replication, and normally syncs changes from the "
    echo -e "primary to the secondary. The LOCAL Pi-hole where you are running this configuration script is"
    echo -e "considered the SECONDARY Pi-hole! The REMOTE Pi-hole where you normally make Gravity Database" 
    echo -e "changes, and is considered the PRIMARY Pi-hole."
    echo_blank
    echo -e "Confused? Please refer back to the documentation."
    echo_lines
    
    MESSAGE="${PROGRAM} ${UI_CONFIG_REQUIRED}"
    echo_info

    MESSAGE="${UI_CORE_APP} ${UI_CONFIG_REMOTE} ${UI_CONFIG_HOSTREQ}"
    echo_blue

    MESSAGE="IP"
    echo_need
    read INPUT_REMOTE_HOST
    
    MESSAGE="${UI_CONFIG_ICMP_TEST} ${INPUT_REMOTE_HOST}"
    echo_stat
    ping -c 3 ${INPUT_REMOTE_HOST} >/dev/null 2>&1
    error_validate

    MESSAGE="Saving ${INPUT_REMOTE_HOST} host to ${CONFIG_FILE}"
    echo_stat
    sed -i "/REMOTE_HOST='192.168.1.10'/c\REMOTE_HOST='${INPUT_REMOTE_HOST}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    error_validate
    
    MESSAGE="${UI_CORE_APP} ${UI_CONFIG_REMOTE} ${UI_CONFIG_USERREQ} for ${INPUT_REMOTE_HOST}"
    echo_blue

    MESSAGE="User"
    echo_need
    read INPUT_REMOTE_USER
    
    MESSAGE="Saving ${INPUT_REMOTE_USER}@${INPUT_REMOTE_HOST} user to ${CONFIG_FILE}"
    echo_stat
    sed -i "/REMOTE_USER='pi'/c\REMOTE_USER='${INPUT_REMOTE_USER}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    error_validate

    generate_sshkey
    
    MESSAGE="${UI_CORE_LOADING} ${CONFIG_FILE}"
    echo_stat
    source ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    error_validate

    echo_lines
    export_sshkey
    echo_lines

    MESSAGE="${UI_CONFIG_SSH_KEYPAIR} ${INPUT_REMOTE_HOST}"
    echo_good_clean

    MESSAGE="${UI_CONFIG_CONT_LOOKUP}"
    echo_stat

    docker_detect
    podman_detect

    if [ "${DOCKERREADY}" == "1" ] || [ "${PODMANREADY}" == "1" ]
    then
        MESSAGE="${UI_CONFIG_CONT_DETECT} ${UI_CONFIG_CONT_DETECTED}"
        echo_good
        MESSAGE="${UI_CORE_LOADING} ${UI_CONFIG_ADVANCED}"
        echo_info
        advanced_config_generate
    else
        MESSAGE="${UI_CONFIG_CONT_DETECT} ${UI_CONFIG_CONT_DETECTNA}"
        echo_good
        MESSAGE="${UI_CONFIG_DOADVANCED}"
        echo_blue
        MESSAGE="${UI_CONFIG_YESNON}"
        echo_need
        read INPUT_ADVANCED_INSTALL
        INPUT_ADVANCED_INSTALL="${INPUT_ADVANCED_INSTALL:-N}"
    
        if [ "${INPUT_ADVANCED_INSTALL}" == "Yes" ] || [ "${INPUT_ADVANCED_INSTALL}" == "yes" ] || [ "${INPUT_ADVANCED_INSTALL}" == "Y" ] || [ "${INPUT_ADVANCED_INSTALL}" == "y" ]
        then
            MESSAGE="${UI_CORE_LOADING} ${UI_CONFIG_ADVANCED}"
            echo_info
        
            advanced_config_generate
        else 
            end_config
        fi
    fi
}

function end_config(){
    echo_lines
    echo -e "Configuration has been completed successfully, if you've still not read the instructions"
    echo -e "please read through ${BLUE}https://github.com/vmstan/gravity-sync/wiki${NC} before you continue!"
    echo_blank
    echo -e "Your next step is to complete a sync of data from your remote Pi-hole to this local Pi-hole."
    echo -e "ex: gravity-sync pull" 
    echo_blank
    echo -e "If this completes successfully you can automate future sync jobs to run at a regular interval."
    echo -e "ex: gravity-sync automate"
    echo_blank
    echo -e "Still confused? Please refer back to the documentation."
    echo_lines
}

## Advanced Configuration Options
function advanced_config_generate {
    MESSAGE="${UI_CONFIG_LOCALSEC} ${UI_CORE_APP} ${UI_CONFIG_INSTANCEREQ}"
    echo_blue
    MESSAGE="${UI_CONFIG_INSTANCETYPE}"
    echo_need
    read INPUT_PH_IN_TYPE
    INPUT_PH_IN_TYPE="${INPUT_PH_IN_TYPE:-default}"
    
    if [ "${INPUT_PH_IN_TYPE}" != "default" ]
    then
        if [ "${INPUT_PH_IN_TYPE}" != "docker" ] && [ "${INPUT_PH_IN_TYPE}" != "podman" ]
        then
            MESSAGE="${UI_CONFIG_LOCALSEC} ${UI_CONFIG_INSTANCE_ERROR}"
            echo_warn
            exit_withchange
        fi

        MESSAGE="${UI_CONFIG_SAVING} ${UI_CONFIG_LOCAL} ${UI_CONFIG_CONTAINER_TYPE} to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# PH_IN_TYPE=''/c\PH_IN_TYPE='${INPUT_PH_IN_TYPE}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
        
        MESSAGE="${UI_CONFIG_CONT_DETECT} ${UI_CONFIG_IMAGES} ${UI_CONFIG_CONT_DETECTED}"
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
        
        MESSAGE="${UI_CONFIG_LOCALSEC} ${UI_CORE_APP} ${UI_CONFIG_INSTANCENAME}"
        echo_blue
        MESSAGE="${UI_CONFIG_PIHOLE_DEFAULT}"
        echo_need
        read INPUT_DOCKER_CON
        INPUT_DOCKER_CON="${INPUT_DOCKER_CON:-pihole}"
        
        if [ "${INPUT_DOCKER_CON}" != "pihole" ]
        then
            MESSAGE="${UI_CONFIG_SAVING} ${UI_CONFIG_LOCAL} ${UI_CONFIG_CONTAINER_NAME} to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DOCKER_CON=''/c\DOCKER_CON='${INPUT_DOCKER_CON}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
        
        MESSAGE="${UI_CONFIG_LOCALSEC} ${UI_CORE_APP} ${UI_CONFIG_ETC_VOLPATH}" 
        echo_blue
        MESSAGE="${UI_CONFIG_ETC_VOLPATH_EXAMPLE}"
        echo_need
        read INPUT_PIHOLE_DIR
        
        if [ "${INPUT_PIHOLE_DIR}" != "" ]
        then
            MESSAGE="${UI_CONFIG_SAVING} ${UI_CONFIG_LOCAL} ${UI_CORE_APP} ${UI_CONFIG_ETC_VOLPATH} to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# PIHOLE_DIR=''/c\PIHOLE_DIR='${INPUT_PIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
            SKIP_PIHOLE_DIR="1"
        else
            MESSAGE="${UI_CONFIG_SETTING_REQUIRED}"
            echo_warn
            exit_withchange
        fi
        
        MESSAGE="${UI_CONFIG_LOCALSEC} ${UI_CORE_APP_DNS} ${UI_CONFIG_ETC_VOLPATH}"
        echo_blue
        MESSAGE="${UI_CONFIG_ETC_VOLDNSQ_EXAMPLE}"
        echo_need
        read INPUT_DNSMAQ_DIR
        
        if [ "${INPUT_DNSMAQ_DIR}" != "" ]
        then
            MESSAGE="Saving Local/Secondary ${UI_CORE_APP_DNS} Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# DNSMAQ_DIR=''/c\DNSMAQ_DIR='${INPUT_DNSMAQ_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
            SKIP_DNSMASQ_DIR="1"
        else
            MESSAGE="${UI_CONFIG_SETTING_REQUIRED}"
            echo_warn
            exit_withchange
        fi
        
        MESSAGE="Saving Local/Secondary Volume Ownership to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# FILE_OWNER=''/c\FILE_OWNER='999:999'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
    MESSAGE="${UI_CONFIG_REMOTEPRI} ${UI_CORE_APP} ${UI_CONFIG_INSTANCEREQ}"
    echo_blue
    MESSAGE="${UI_CONFIG_INSTANCETYPE}"
    echo_need
    read INPUT_RH_IN_TYPE
    INPUT_RH_IN_TYPE="${INPUT_RH_IN_TYPE:-default}"
    
    if [ "${INPUT_RH_IN_TYPE}" != "default" ]
    then
        if [ "${INPUT_RH_IN_TYPE}" != "docker" ] && [ "${INPUT_RH_IN_TYPE}" != "podman" ]
        then
            MESSAGE="${UI_CONFIG_REMOTEPRI} ${UI_CONFIG_INSTANCE_ERROR}"
            echo_warn
            exit_withchange
        fi
        MESSAGE="Saving ${UI_CONFIG_REMOTE} ${UI_CONFIG_CONTAINER_TYPE} to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# RH_IN_TYPE=''/c\RH_IN_TYPE='${INPUT_RH_IN_TYPE}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
        
        MESSAGE="${UI_CONFIG_REMOTEPRI} Container Name? (Leave blank for default 'pihole')"
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
        
        MESSAGE="${UI_CONFIG_REMOTEPRI} ${UI_CORE_APP} 'etc' Volume Path? (Required, no trailing slash)"
        echo_need
        read INPUT_RIHOLE_DIR
        
        if [ "${INPUT_RIHOLE_DIR}" != "" ]
        then
            MESSAGE="Saving Primary/Remote ${UI_CORE_APP} Volume to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RIHOLE_DIR=''/c\RIHOLE_DIR='${INPUT_RIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
            SKIP_RIHOLE_DIR="1"
        else
            MESSAGE="${UI_CONFIG_SETTING_REQUIRED}"
            echo_warn
            exit_withchange
        fi
        
        MESSAGE="${UI_CONFIG_REMOTEPRI} DNSMASQ 'etc' Volume Path? (Required, no trailing slash)"
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
            MESSAGE="${UI_CONFIG_SETTING_REQUIRED}"
            echo_warn
            exit_withchange
        fi
        
        MESSAGE="Saving Primary/Remote Volume Ownership to ${CONFIG_FILE}"
        echo_stat
        sed -i "/# RILE_OWNER=''/c\RILE_OWNER='999:999'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
        
    if [ "$SKIP_PIHOLE_DIR" != "1" ]
    then
        MESSAGE="${UI_CONFIG_LOCALSEC} ${UI_CORE_APP} Settings Directory Path? (Leave blank for default '/etc/pihole')"
        echo_need
        read INPUT_PIHOLE_DIR
        INPUT_PIHOLE_DIR="${INPUT_PIHOLE_DIR:-/etc/pihole}"
        
        if [ "${INPUT_PIHOLE_DIR}" != "/etc/pihole" ]
        then
            MESSAGE="Saving Local/Secondary ${UI_CORE_APP} Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# PIHOLE_DIR=''/c\PIHOLE_DIR='${INPUT_PIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_RIHOLE_DIR" != "1" ]
    then
        MESSAGE="${UI_CONFIG_REMOTEPRI} ${UI_CORE_APP} Settings Directory Path? (Leave blank for default '/etc/pihole')"
        echo_need
        read INPUT_RIHOLE_DIR
        INPUT_RIHOLE_DIR="${INPUT_RIHOLE_DIR:-/etc/pihole}"
        
        if [ "${INPUT_RIHOLE_DIR}" != "/etc/pihole" ]
        then
            MESSAGE="Saving Primary/Remote ${UI_CORE_APP} Settings Directory Path to ${CONFIG_FILE}"
            echo_stat
            sed -i "/# RIHOLE_DIR=''/c\RIHOLE_DIR='${INPUT_RIHOLE_DIR}'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi
    
    if [ "$SKIP_DNSMASQ_DIR" != "1" ]
    then
        MESSAGE="${UI_CONFIG_LOCALSEC} DNSMASQ Settings Directory Path? (Leave blank for default '/etc/dnsmasq.d')"
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
        MESSAGE="${UI_CONFIG_REMOTEPRI} DNSMASQ Settings Directory Path? (Leave blank for default '/etc/dnsmasq.d')"
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
    
    MESSAGE="${UI_ENABLE_REPLICATION_QUEST} ${UI_CUSTOM_NAME}? ${UI_CONFIG_YESNOY}"
    echo_need
    read INPUT_SKIP_CUSTOM
    INPUT_SKIP_CUSTOM="${INPUT_SKIP_CUSTOM:-Y}"
    
    if [ "${INPUT_SKIP_CUSTOM}" != "Y" ]
    then
        MESSAGE="${UI_DNS_NAME} ${UI_CONFIG_PREF_SAVED} ${CONFIG_FILE}"
        echo_stat
        sed -i "/# SKIP_CUSTOM=''/c\SKIP_CUSTOM='1'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
        error_validate
    fi
    
    if [ "${INPUT_SKIP_CUSTOM}" == "Y" ]
    then
        MESSAGE="${UI_ENABLE_REPLICATION_QUEST} ${UI_CNAME_NAME}? ${UI_CONFIG_YESNOY}"
        echo_need
        read INPUT_INCLUDE_CNAME
        INPUT_INCLUDE_CNAME="${INPUT_INCLUDE_CNAME:-Y}"
        
        if [ "${INPUT_INCLUDE_CNAME}" == "Y" ]
        then
            MESSAGE="${UI_CNAME_NAME} ${UI_CONFIG_PREF_SAVED} ${CONFIG_FILE}"
            echo_stat
            sed -i "/# INCLUDE_CNAME=''/c\INCLUDE_CNAME='1'" ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
            error_validate
        fi
    fi

    end_config
}

## Delete Existing Configuration
function config_delete {
    source ${LOCAL_FOLDR}/settings/${CONFIG_FILE}
    MESSAGE="${CONFIG_FILE} already exists"
    echo_info  
  
    MESSAGE="${UI_CONFIG_AREYOUSURE}"
    echo_blue

    intent_validate

    MESSAGE="${UI_CONFIG_ERASING} ${CONFIG_FILE}"
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
    MESSAGE="${UI_CONFIG_BASH}"
    echo_stat
    
    echo -e "alias gravity-sync='${GS_FILEPATH}'" | sudo tee -a /etc/bash.bashrc > /dev/null
        error_validate

    MESSAGE="${UI_CONFIG_ALIAS}"
    echo_info
}
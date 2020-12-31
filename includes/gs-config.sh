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
    
    echo -e "========================================================"
    cat ${LOCAL_FOLDR}/${CONFIG_FILE}
    echo -e "========================================================"
    
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
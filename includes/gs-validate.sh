# GRAVITY SYNC BY VMSTAN #####################
# gs-validate.sh #############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Validate GS Folders
function validate_gs_folders {
    MESSAGE="${UI_VAL_GS_FOLDERS}"
    echo_stat
    
    if [ ! -d ${LOCAL_FOLDR} ] || [ ! -d ${LOCAL_FOLDR}/${BACKUP_FOLD} ] || [ ! -d ${LOCAL_FOLDR}/settings ] || [ ! -d ${LOG_PATH} ]
    then
        MESSAGE="${UI_VAL_GS_FOLDERS_FAIL}"
        echo_fail
        exit_nochange
    fi
    
    echo_sameline
}

## Validate Pi-hole Folders
function validate_ph_folders {
    MESSAGE="${UI_VALIDATING} ${UI_CORE_APP}"
    echo_stat
    
    if [ "$PH_IN_TYPE" == "default" ]
    then
        if [ ! -f ${PIHOLE_BIN} ]
        then
            MESSAGE="${UI_VALIDATING_FAIL_BINARY} ${UI_CORE_APP}"
            echo_fail
            exit_nochange
        fi
    elif [ "$PH_IN_TYPE" == "docker" ]
    then
        FTLCHECK=$(sudo docker container ls | grep "${CONTAIMAGE}")
        if [ "$FTLCHECK" == "" ]
        then
            MESSAGE="${UI_VALIDATING_FAIL_CONTAINER} ${UI_CORE_APP}"
            echo_fail
            exit_nochange
        fi
    elif [ "$PH_IN_TYPE" == "podman" ]
    then
        FTLCHECK=$(sudo podman container ls | grep "${CONTAIMAGE}")
        if [ "$FTLCHECK" == "" ]
        then
            MESSAGE="${UI_VALIDATING_FAIL_CONTAINER} ${UI_CORE_APP}"
            echo_fail
            exit_nochange
        fi
    fi
    
    if [ ! -d ${PIHOLE_DIR} ]
    then
        MESSAGE="${UI_VALIDATING_FAIL_FOLDER} ${UI_CORE_APP}"
        echo_fail
        exit_nochange
    fi
    
    echo_sameline
}

## Validate DNSMASQ Folders
function validate_dns_folders {
    MESSAGE="${UI_VALIDATING} ${UI_CORE_APP_DNS}"
    echo_stat
    
    if [ ! -d ${DNSMAQ_DIR} ]
    then
        MESSAGE="${UI_VALIDATING_FAIL_FOLDER} ${UI_CORE_APP_DNS}"
        echo_fail
        exit_nochange
    fi
    echo_sameline
}

## Validate SQLite3
function validate_sqlite3 {
    MESSAGE="${UI_VALIDATING} ${UI_CORE_APP_SQL}"
    echo_stat
    if hash sqlite3 2>/dev/null
    then
        # MESSAGE="SQLITE3 Utility Detected"
        echo_sameline
    else
        MESSAGE="${UI_VALIDATING_FAIL_BINARY} ${UI_CORE_APP_SQL}"
        echo_warn
        
        #MESSAGE="Installing SQLLITE3 with ${PKG_MANAGER}"
        #echo_stat
        
        #${PKG_INSTALL} sqllite3 >/dev/null 2>&1
        #error_validate
    fi
}

## Validate SSHPASS
function validate_os_sshpass {
    MESSAGE="Connecting to ${REMOTE_HOST}"
    echo_stat
    
    CMD_TIMEOUT='5'
    CMD_REQUESTED="exit"
    create_sshcmd
}

## Detect Package Manager
function distro_check {
    if hash apt-get 2>/dev/null
    then
        PKG_MANAGER="apt-get"
        PKG_INSTALL="sudo apt-get --yes --no-install-recommends --quiet install"
    elif hash rpm 2>/dev/null
    then
        if hash dnf 2>/dev/null
        then
            PKG_MANAGER="dnf"
        elif hash yum 2>/dev/null
        then
            PKG_MANAGER="yum"
        else
            MESSAGE="Unable to find OS Package Manager"
            echo_info
            exit_nochange
        fi
        PKG_INSTALL="sudo ${PKG_MANAGER} install -y"
    else
        MESSAGE="Unable to find OS Package Manager"
        echo_info
        exit_nochange
    fi
}

## Dropbear Warning
function dbclient_warning {
    if hash dbclient 2>/dev/null
    then
        if hash ssh 2>/dev/null
        then
            NOEMPTYBASHIF="1"
        else
            MESSAGE="${UI_DROPBEAR_DEP}"
            echo_warn
        fi
    fi
}

## Validate Domain Database Permissions
function validate_gravity_permissions() {
    MESSAGE="${UI_VAL_FILE_OWNERSHIP} ${UI_GRAVITY_NAME}"
    echo_stat
    
    GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk 'OFS=":" {print $3,$4}')
    if [ "$GRAVDB_OWN" == "$FILE_OWNER" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="${UI_COMPENSATE}"
        echo_warn
        
        MESSAGE="${UI_SET_FILE_OWNERSHIP} ${UI_GRAVITY_NAME}"
        echo_stat
        sudo chown ${FILE_OWNER} ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
        error_validate
    fi
    
    MESSAGE="${UI_VAL_FILE_PERMISSION} of ${UI_GRAVITY_NAME}"
    echo_stat
    
    GRAVDB_RWE=$(namei -m ${PIHOLE_DIR}/${GRAVITY_FI} | grep -v f: | grep ${GRAVITY_FI} | awk '{print $1}')
    if [ "$GRAVDB_RWE" = "-rw-rw-r--" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="${UI_COMPENSATE}"
        echo_warn
        
        MESSAGE="${UI_SET_FILE_PERMISSION} ${UI_GRAVITY_NAME}"
        echo_stat
        sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
        error_validate
    fi
}

## Validate Local DNS Records Permissions
function validate_custom_permissions() {
    MESSAGE="${UI_VAL_FILE_OWNERSHIP} ${UI_CUSTOM_NAME}"
    echo_stat
    
    CUSTOMLS_OWN=$(ls -ld ${PIHOLE_DIR}/${CUSTOM_DNS} | awk '{print $3 $4}')
    if [ "$CUSTOMLS_OWN" == "rootroot" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="${UI_COMPENSATE}"
        echo_warn
        
        MESSAGE="${UI_SET_FILE_OWNERSHIP} ${UI_CUSTOM_NAME}"
        echo_stat
        sudo chown root:root ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
        error_validate
    fi
    
    MESSAGE="${UI_VAL_FILE_PERMISSION} ${UI_CUSTOM_NAME}"
    echo_stat
    
    CUSTOMLS_RWE=$(namei -m ${PIHOLE_DIR}/${CUSTOM_DNS} | grep -v f: | grep ${CUSTOM_DNS} | awk '{print $1}')
    if [ "$CUSTOMLS_RWE" == "-rw-r--r--" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="${UI_COMPENSATE}"
        echo_warn
        
        MESSAGE="${UI_SET_FILE_PERMISSION} ${UI_CUSTOM_NAME}"
        echo_stat
        sudo chmod 644 ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
        error_validate
    fi
}

## Validate Local DNS CNAME Permissions
function validate_cname_permissions() {
    MESSAGE="${UI_VAL_FILE_OWNERSHIP} ${UI_CNAME_NAME}"
    echo_stat
    
    CNAMELS_OWN=$(ls -ld ${DNSMAQ_DIR}/${CNAME_CONF} | awk '{print $3 $4}')
    if [ "$CNAMELS_OWN" == "rootroot" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="${UI_COMPENSATE}"
        echo_warn
        
        MESSAGE="${UI_SET_FILE_OWNERSHIP} ${UI_CNAME_NAME}"
        echo_stat
        sudo chown root:root ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
        error_validate
    fi
    
    MESSAGE="${UI_VAL_FILE_PERMISSION} ${UI_CNAME_NAME}"
    echo_stat
    
    CNAMELS_RWE=$(namei -m ${DNSMAQ_DIR}/${CNAME_CONF} | grep -v f: | grep ${CNAME_CONF} | awk '{print $1}')
    if [ "$CNAMELS_RWE" == "-rw-r--r--" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="${UI_COMPENSATE}"
        echo_warn
        
        MESSAGE="${UI_SET_FILE_PERMISSION} ${UI_CNAME_NAME}"
        echo_stat
        sudo chmod 644 ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
        error_validate
    fi
}


# GRAVITY SYNC BY VMSTAN #####################
# gs-validate.sh #############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Validate GS Folders
function validate_gs_folders {
    MESSAGE="Validating ${PROGRAM} folders on $HOSTNAME"
    echo_stat
    if [ ! -d ${LOCAL_FOLDR} ]
    then
        MESSAGE="Unable to validate ${PROGRAM} folders on $HOSTNAME"
        echo_fail
        exit_nochange
    fi
    
    if [ ! -d ${LOCAL_FOLDR}/${BACKUP_FOLD} ]
    then
        MESSAGE="Unable to validate ${PROGRAM} backup folder on $HOSTNAME"
        echo_fail
        exit_nochange
    fi
    echo_sameline
}

## Validate Pi-hole Folders
function validate_ph_folders {
    MESSAGE="Validating Pi-hole configuration"
    echo_stat
    
    if [ "$PH_IN_TYPE" == "default" ]
    then
        if [ ! -f ${PIHOLE_BIN} ]
        then
            MESSAGE="Unable to validate that Pi-Hole is installed on $HOSTNAME"
            echo_fail
            exit_nochange
        fi
    elif [ "$PH_IN_TYPE" == "docker" ]
    then
        FTLCHECK=$(sudo docker container ls | grep "${CONTAIMAGE}")
        if [ "$FTLCHECK" == "" ]
        then
            MESSAGE="Unable to validate that Pi-Hole container is running on $HOSTNAME"
            echo_fail
            exit_nochange
        fi
    elif [ "$PH_IN_TYPE" == "podman" ]
    then
        FTLCHECK=$(sudo podman container ls | grep "${CONTAIMAGE}")
        if [ "$FTLCHECK" == "" ]
        then
            MESSAGE="Unable to validate that Pi-Hole container is running on $HOSTNAME"
            echo_fail
            exit_nochange
        fi
    fi
    
    if [ ! -d ${PIHOLE_DIR} ]
    then
        MESSAGE="Unable to validate the Pi-Hole configuration directory location"
        echo_fail
        exit_nochange
    fi
    echo_sameline
}

## Validate DNSMASQ Folders
function validate_dns_folders {
    MESSAGE="Validating DNSMASQ configuration"
    echo_stat
    
    if [ ! -d ${DNSMAQ_DIR} ]
    then
        MESSAGE="Unable to validate the DNSMASQ configuration directory"
        echo_fail
        exit_nochange
    fi
    echo_sameline
}

## Validate SQLite3
function validate_sqlite3 {
    MESSAGE="Validating SQLITE3 installation"
    echo_stat
    if hash sqlite3 2>/dev/null
    then
        # MESSAGE="SQLITE3 Utility Detected"
        echo_sameline
    else
        MESSAGE="Unable to validate SQLITE3 installation on $HOSTNAME"
        echo_warn
        
        #MESSAGE="Installing SQLLITE3 with ${PKG_MANAGER}"
        #echo_stat
        
        #${PKG_INSTALL} sqllite3 >/dev/null 2>&1
        #error_validate
    fi
}

## Validate SSHPASS
function validate_os_sshpass {
    # SSHPASSWORD=''
    
    # if hash sshpass 2>/dev/null
    # then
    #	MESSAGE="SSHPASS Utility Detected"
    #	echo_warn
    #		if [ -z "$REMOTE_PASS" ]
    #		then
    #			MESSAGE="Using SSH Key-Pair Authentication"
    #			echo_info
    #		else
    #			MESSAGE="Testing Authentication Options"
    #			echo_stat
    
    #			timeout 5 ssh -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} 'exit' >/dev/null 2>&1
    #			if [ "$?" != "0" ]
    #			then
    #				SSHPASSWORD="sshpass -p ${REMOTE_PASS}"
    #				MESSAGE="Using SSH Password Authentication"
    #				echo_warn
    #			else
    #				MESSAGE="Valid Key-Pair Detected ${NC}(${RED}Password Ignored${NC})"
    #				echo_info
    #			fi
    #		fi
    # else
    #    SSHPASSWORD=''
    #	MESSAGE="Using SSH Key-Pair Authentication"
    #	echo_info
    # fi
    
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
            MESSAGE="Dropbear support has been deprecated"
            echo_warn
        fi
    fi
}

## Validate Domain Database Permissions
function validate_gravity_permissions() {
    MESSAGE="Validating file ownership of Domain Database"
    echo_stat
    
    GRAVDB_OWN=$(ls -ld ${PIHOLE_DIR}/${GRAVITY_FI} | awk 'OFS=":" {print $3,$4}')
    if [ "$GRAVDB_OWN" == "$FILE_OWNER" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to compensate"
        echo_warn
        
        MESSAGE="Setting file ownership of Domain Database"
        echo_stat
        sudo chown ${FILE_OWNER} ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
        error_validate
    fi
    
    MESSAGE="Validating file permissions of Domain Database"
    echo_stat
    
    GRAVDB_RWE=$(namei -m ${PIHOLE_DIR}/${GRAVITY_FI} | grep -v f: | grep ${GRAVITY_FI} | awk '{print $1}')
    if [ "$GRAVDB_RWE" = "-rw-rw-r--" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to compensate"
        echo_warn
        
        MESSAGE="Setting file ownership of Domain Database"
        echo_stat
        sudo chmod 664 ${PIHOLE_DIR}/${GRAVITY_FI} >/dev/null 2>&1
        error_validate
    fi
}

## Validate Local DNS Records Permissions
function validate_custom_permissions() {
    MESSAGE="Validating file ownership on Local DNS Records"
    echo_stat
    
    CUSTOMLS_OWN=$(ls -ld ${PIHOLE_DIR}/${CUSTOM_DNS} | awk '{print $3 $4}')
    if [ "$CUSTOMLS_OWN" == "rootroot" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to compensate"
        echo_warn
        
        MESSAGE="Setting file ownership on Local DNS Records"
        echo_stat
        sudo chown root:root ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
        error_validate
    fi
    
    MESSAGE="Validating file permissions on Local DNS Records"
    echo_stat
    
    CUSTOMLS_RWE=$(namei -m ${PIHOLE_DIR}/${CUSTOM_DNS} | grep -v f: | grep ${CUSTOM_DNS} | awk '{print $1}')
    if [ "$CUSTOMLS_RWE" == "-rw-r--r--" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to compensate"
        echo_warn
        
        MESSAGE="Setting file ownership on Local DNS Records"
        echo_stat
        sudo chmod 644 ${PIHOLE_DIR}/${CUSTOM_DNS} >/dev/null 2>&1
        error_validate
    fi
}

## Validate Local DNS CNAME Permissions
function validate_cname_permissions {
    MESSAGE="Validating file ownership on Local DNS CNAMEs"
    echo_stat
    
    CNAMELS_OWN=$(ls -ld ${DNSMAQ_DIR}/${CNAME_CONF} | awk '{print $3 $4}')
    if [ "$CNAMELS_OWN" == "rootroot" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to compensate"
        echo_warn
        
        MESSAGE="Setting file ownership on Local DNS CNAMEs"
        echo_stat
        sudo chown root:root ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
        error_validate
    fi
    
    MESSAGE="Validating file permissions on Local DNS CNAMEs"
    echo_stat
    
    CNAMELS_RWE=$(namei -m ${DNSMAQ_DIR}/${CNAME_CONF} | grep -v f: | grep ${CNAME_CONF} | awk '{print $1}')
    if [ "$CNAMELS_RWE" == "-rw-r--r--" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to compensate"
        echo_warn
        
        MESSAGE="Setting file ownership on Local DNS CNAMEs"
        echo_stat
        sudo chmod 644 ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
        error_validate
    fi
}


# GRAVITY SYNC BY VMSTAN #####################
# gs-validate.sh #############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Validate GS Folders
function validate_gs_folders {
    MESSAGE="Validating ${PROGRAM} Folders on $HOSTNAME"
    echo_stat
    if [ ! -d ${LOCAL_FOLDR} ]
    then
        MESSAGE="Unable to Validate ${PROGRAM} Folders on $HOSTNAME"
        echo_fail
        exit_nochange
    fi
    
    if [ ! -d ${LOCAL_FOLDR}/${BACKUP_FOLD} ]
    then
        MESSAGE="Unable to Validate ${PROGRAM} Backup Folder on $HOSTNAME"
        echo_fail
        exit_nochange
    fi
    echo_good
}

## Validate Pi-hole Folders
function validate_ph_folders {
    MESSAGE="Validating Pi-hole Configuration"
    echo_stat
    
    if [ "$PH_IN_TYPE" == "default" ]
    then
        if [ ! -f ${PIHOLE_BIN} ]
        then
            MESSAGE="Unable to Validate that Pi-Hole is Installed"
            echo_fail
            exit_nochange
        fi
    elif [ "$PH_IN_TYPE" == "docker" ]
    then
        FTLCHECK=$(sudo docker container ls | grep 'pihole/pihole')
        if [ "$FTLCHECK" == "" ]
        then
            MESSAGE="Unable to Validate that Pi-Hole is Installed"
            echo_fail
            exit_nochange
        fi
    elif [ "$PH_IN_TYPE" == "podman" ]
    then
        FTLCHECK=$(sudo podman container ls | grep 'pihole/pihole')
        if [ "$FTLCHECK" == "" ]
        then
            MESSAGE="Unable to Validate that Pi-Hole is Installed"
            echo_fail
            exit_nochange
        fi
    fi
    
    if [ ! -d ${PIHOLE_DIR} ]
    then
        MESSAGE="Unable to Validate Pi-Hole Configuration Directory"
        echo_fail
        exit_nochange
    fi
    echo_good
}

## Validate DNSMASQ Folders
function validate_dns_folders {
    MESSAGE="Validating DNSMASQ Configuration"
    echo_stat
    
    if [ ! -d ${DNSMAQ_DIR} ]
    then
        MESSAGE="Unable to Validate DNSMASQ Configuration Directory"
        echo_fail
        exit_nochange
    fi
    echo_good
}

## Validate SQLite3
function validate_sqlite3 {
    MESSAGE="Validating SQLITE Installed on $HOSTNAME"
    echo_stat
    if hash sqlite3 2>/dev/null
    then
        # MESSAGE="SQLITE3 Utility Detected"
        echo_good
    else
        MESSAGE="Unable to Validate SQLITE Install on $HOSTNAME"
        echo_warn
        
        MESSAGE="Installing SQLLITE3 with ${PKG_MANAGER}"
        echo_stat
        
        ${PKG_INSTALL} sqllite3 >/dev/null 2>&1
        error_validate
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
    
    MESSAGE="Validating Connection to ${REMOTE_HOST}"
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
            MESSAGE="Dropbear support has been deprecated - please convert to OpenSSH"
            echo_warn
        fi
    fi
}

## Validate CNAME Permissions
function validate_cname_permissions {
    CNAMELS_OWN=$(ls -ld ${DNSMAQ_DIR}/${CNAME_CONF} | awk '{print $3 $4}')
    if [ "$CNAMELS_OWN" == "rootroot" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to Compensate"
        echo_warn
        
        MESSAGE="Setting Ownership on ${CNAME_CONF}"
        echo_stat
        sudo chown root:root ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
        error_validate
    fi
    
    MESSAGE="Validating Permissions on ${CNAME_CONF}"
    echo_stat
    
    CNAMELS_RWE=$(namei -m ${DNSMAQ_DIR}/${CNAME_CONF} | grep -v f: | grep ${CNAME_CONF} | awk '{print $1}')
    if [ "$CNAMELS_RWE" == "-rw-r--r--" ]
    then
        echo_good
    else
        echo_fail
        
        MESSAGE="Attempting to Compensate"
        echo_warn
        
        MESSAGE="Setting Ownership on ${CNAME_CONF}"
        echo_stat
        sudo chmod 644 ${DNSMAQ_DIR}/${CNAME_CONF} >/dev/null 2>&1
        error_validate
    fi
}
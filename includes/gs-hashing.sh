# GRAVITY SYNC BY VMSTAN #####################
# gs-hasing.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Validate Sync Required
function md5_compare {
    HASHMARK='0'
    
    MESSAGE="Hashing the primary (remote) ${GRAVITY_FI}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//')
    error_validate
    
    MESSAGE="Comparing to $HOSTNAME's ${GRAVITY_FI}"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
    error_validate
    
    if [ "$primaryDBMD5" == "$last_primaryDBMD5" ] && [ "$secondDBMD5" == "$last_secondDBMD5" ]
    then
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="Differenced ${GRAVITY_FI} detected"
        echo_warn
        HASHMARK=$((HASHMARK+1))
    fi
    
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="Scanning the primary (remote) Local DNS Records"
                echo_stat
                
                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'")
                error_validate
                
                MESSAGE="Comparing to $HOSTNAME's Local DNS Records"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                error_validate
                
                if [ "$primaryCLMD5" == "$last_primaryCLMD5" ] && [ "$secondCLMD5" == "$last_secondCLMD5" ]
                then
                    HASHMARK=$((HASHMARK+0))
                else
                    MESSAGE="Differenced ${CUSTOM_DNS} file detected"
                    echo_warn
                    HASHMARK=$((HASHMARK+1))
                fi
            else
                MESSAGE="No ${CUSTOM_DNS} file detected on ${REMOTE_HOST}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${REMOTE_HOST} has ${CUSTOM_DNS}"
                HASHMARK=$((HASHMARK+1))
                echo_info
            fi
            MESSAGE="No ${CUSTOM_DNS} file detected on $HOSTNAME"
            echo_info
        fi
    fi
    
    if [ "${SKIP_CUSTOM}" != '1' ]
    then
        if [ "${INCLUDE_CNAME}" == "1" ]
        then
            if [ -f ${DNSMAQ_DIR}/${CNAME_CONF} ]
            then
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="Reviewing primary (remote) Local DNS CNAME extensions"
                    echo_stat
                    
                    primaryCNMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//'")
                    error_validate
                    
                    MESSAGE="Comparing to $HOSTNAME's Local DNS CNAME extensions"
                    echo_stat
                    secondCNMD5=$(md5sum ${DNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//')
                    error_validate
                    
                    if [ "$primaryCNMD5" == "$last_primaryCNMD5" ] && [ "$secondCNMD5" == "$last_secondCNMD5" ]
                    then
                        HASHMARK=$((HASHMARK+0))
                    else
                        MESSAGE="Differenced ${CNAME_CONF} file detected"
                        echo_warn
                        HASHMARK=$((HASHMARK+1))
                    fi
                else
                    MESSAGE="No ${CNAME_CONF} file detected on ${REMOTE_HOST}"
                    echo_info
                fi
            else
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="${REMOTE_HOST} has ${CNAME_CONF}"
                    HASHMARK=$((HASHMARK+1))
                    echo_info
                fi
                
                MESSAGE="No ${CNAME_CONF} file detected on $HOSTNAME"
                echo_info
            fi
        fi
    fi
    
    if [ "$HASHMARK" != "0" ]
    then
        MESSAGE="Replication of Pi-hole settings are required"
        echo_warn
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="No replication is required at this time"
        echo_info
        backup_cleanup
        exit_nochange
    fi
}

function previous_md5 {
    if [ -f "${LOG_PATH}/${HISTORY_MD5}" ]
    then
        last_primaryDBMD5=$(sed "1q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_secondDBMD5=$(sed "2q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_primaryCLMD5=$(sed "3q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_secondCLMD5=$(sed "4q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_primaryCNMD5=$(sed "5q;d" ${LOG_PATH}/${HISTORY_MD5})
        last_secondCNMD5=$(sed "6q;d" ${LOG_PATH}/${HISTORY_MD5})
    else
        last_primaryDBMD5="0"
        last_secondDBMD5="0"
        last_primaryCLMD5="0"
        last_secondCLMD5="0"
        last_primaryCNMD5="0"
        last_secondCNMD5="0"
    fi
}

function md5_recheck {
    MESSAGE="Performing replicator diagnostics"
    echo_info
    
    HASHMARK='0'
    
    MESSAGE="Reanalyzing ${GRAVITY_FI} on ${REMOTE_HOST}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//')
    silent_error_validate
    
    MESSAGE="Reanalyzing ${GRAVITY_FI} on $HOSTNAME"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
    silent_error_validate
    
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="Reanalyzing ${CUSTOM_DNS} on ${REMOTE_HOST}"
                echo_stat
                
                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'")
                silent_error_validate
                
                MESSAGE="Reanalyzing ${CUSTOM_DNS} on $HOSTNAME"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                silent_error_validate
            else
                MESSAGE="No ${CUSTOM_DNS} detected on ${REMOTE_HOST}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${REMOTE_HOST} has ${CUSTOM_DNS}"
                echo_info
            fi
            MESSAGE="No ${CUSTOM_DNS} detected on $HOSTNAME"
            echo_info
        fi
    fi
    
    if [ "${SKIP_CUSTOM}" != '1' ]
    then
        if [ "${INCLUDE_CNAME}" == "1" ]
        then
            if [ -f ${DNSMAQ_DIR}/${CNAME_CONF} ]
            then
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="Reanalyzing ${CNAME_CONF} on ${REMOTE_HOST}"
                    echo_stat
                    
                    primaryCNMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//'")
                    silent_error_validate
                    
                    MESSAGE="Reanalyzing ${CNAME_CONF} on $HOSTNAME"
                    echo_stat
                    secondCNMD5=$(md5sum ${DNSMAQ_DIR}/${CNAME_CONF} | sed 's/\s.*$//')
                    silent_error_validate
                else
                    MESSAGE="No ${CNAME_CONF} detected on ${REMOTE_HOST}"
                    echo_info
                fi
            else
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${CNAME_CONF}
                then
                    REMOTE_CNAME_DNS="1"
                    MESSAGE="${REMOTE_HOST} has ${CNAME_CONF}"
                    echo_info
                fi
                
                MESSAGE="No ${CNAME_CONF} detected on $HOSTNAME"
                echo_info
            fi
        fi
    fi
}
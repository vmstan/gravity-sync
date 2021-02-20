# GRAVITY SYNC BY VMSTAN #####################
# gs-ui.sh ###################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

# Interface Settings
UI_GRAVITY_NAME='Domain Database'
UI_CUSTOM_NAME='Local DNS Records'
UI_CNAME_NAME='Local DNS CNAMEs'

# Validation
UI_VALIDATING='Validating configuration of'
UI_VALIDATING_FAIL_CONTAINER='Unable to validate running container instance of'
UI_VALIDATING_FAIL_FOLDER='Unable to validate configuration folder for'
UI_VALIDATING_FAIL_BINARY='Unable to validate the availibility of'
UI_CORE_APP='Pi-hole'
UI_CORE_APP_DNS='DNSMASQ'
UI_CORE_APP_SQL='SQLITE3'
UI_COMPENSATE='Attempting to compensate'
UI_SET_FILE_OWNERSHIP='Setting file ownership on'
UI_SET_FILE_PERMISSION='Setting file permissions on'
UI_VAL_FILE_OWNERSHIP='Validating file ownership on'
UI_VAL_FILE_PERMISSION='Validating file permissions on'
UI_VAL_GS_FOLDERS="Validating ${PROGRAM} folders on $HOSTNAME"
UI_VAL_GS_FOLDERS_FAIL="Unable to validate ${PROGRAM} folders on $HOSTNAME"

# Configuration
UI_DROPBEAR_DEP='Dropbear support has been deprecated'

# Pull/Push
UI_PULL_PRIMARY='Pulling the primary'
UI_PUSH_SECONDARY='Pushing the secondary'
UI_REPLACE_SECONDARY='Replacing the secondary'
UI_PULL_RELOAD_WAIT='Isolating regeneration pathways'
UI_PUSH_RELOAD_WAIT='Inverting tachyon pulses'
UI_FTLDNS_CONFIG_UPDATE='Updating secondary FTLDNS configuration'
UI_FTLDNS_CONFIG_RELOAD='Reloading secondary FTLDNS services'
UI_FTLDNS_CONFIG_PUSH_UPDATE='Updating primary FTLDNS configuration'
UI_FTLDNS_CONFIG_PUSH_RELOAD='Reloading primary FTLDNS services'

# Logging
UI_LOGGING_SUCCESS='Logging successful'
UI_LOGGING_HASHES='Saving the updated hashes from this replication'
UI_LOGGING_DISPLAY='Displaying output of previous jobs'
UI_LOGGING_EMPTY='is empty'
UI_LOGGING_MISSING='is missing'
UI_LOGGING_RECENT_COMPLETE='Recent complete executions of'

# Backup
UI_BACKUP_PRIMARY='Performing backup of primary'
UI_BACKUP_SECONDARY='Performing backup of secondary'
UI_BACKUP_PURGE='Purging redundant backups on secondary Pi-hole instance'
UI_BACKUP_REMAIN='days of backups remain'

# Restore
UI_RESTORE_WARNING="This will overwrite your current Pi-hole settings on $HOSTNAME with a previous version!"
UI_RESTORE_INVALID='Invalid restoration request'
UI_RESTORE_SELECT_DATE='Select backup date from which to restore the'
UI_RESTORE_SKIPPING='Skipping restore of'
UI_RESTORE_BACKUP_SELECTED='backup selected for restoration'
UI_RESTORE_BACKUP_UNAVAILABLE='backups are unavailable'
UI_RESTORE_FROM='restoring from'
UI_RESTORE_TIME_TRAVEL='Preparing calculations for time travel'
UI_RESTORE_SECONDARY='Restoring the secondary'
UI_RESTORE_PUSH_PROMPT='Do you want to push the restored configuration to the primary Pi-hole? (Y/N)'
UI_RESTORE_PUSH_NOPUSH="Configuration will not be pushed to the primaryp Pi-hole"

UI_INVALID_SELECTION='Invalid selection'

# Purge
UI_PURGE_MATRIX_ALIGNMENT='Realigning dilithium crystal matrix'
UI_PURGE_DELETE_SSH_KEYS='Deleting SSH key-files'
UI_PURGE_CLEANING_DIR="Purging ${PROGRAM} directory"

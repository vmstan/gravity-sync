# GRAVITY SYNC BY VMSTAN #####################
# gs-ui.sh ###################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

# Interface Settings
UI_GRAVITY_NAME='Domain Database'
UI_CUSTOM_NAME='Local DNS Records'
UI_CNAME_NAME='Local DNS CNAMEs'

# Core
UI_INVALID_SELECTION='Invalid selection'
UI_INVALID_DNS_CONFIG='Invalid DNS replication settings in'
UI_CORE_MISSING='Missing'
UI_CORE_LOADING='Loading'
UI_CORE_EVALUATING='Evaluating arguments'
UI_CORE_INIT="Initalizing ${PROGRAM} (${VERSION})"
UI_CORE_RELOCATING='Relocating'

# Exit
UI_EXIT_CALC_END="after $((SCRIPT_END-SCRIPT_START)) seconds"
UI_EXIT_ABORT='aborted'
UI_EXIT_COMPLETE='completed'

# Hashing
UI_HASHING_HASHING='Hashing the primary'
UI_HASHING_COMPARING='Comparing to the secondary'
UI_HASHING_DIFFERNCE='Differences detected in the'
UI_HASHING_DETECTED='has been detected on the'
UI_HASHING_NOTDETECTED='not detected on the'
UI_HASHING_PRIMARY='primary host'
UI_HASHING_SECONDARY='secondary host'
UI_HASHING_REQUIRED='Replication of Pi-hole settings is required'
UI_HASHING_NOREP='No replication is required at this time'
UI_HASHING_DIAGNOSTICS='Performing replicator diagnostics'
UI_HASHING_REHASHING='Rehashing the primary'
UI_HASHING_RECOMPARING='Recomparing to the secondary'

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
UI_BACKUP_COPY='Pulling backup of primary'
UI_BACKUP_SECONDARY='Performing backup of secondary'
UI_BACKUP_PURGE='Purging redundant backups on secondary Pi-hole instance'
UI_BACKUP_REMAIN='days of backups remain'
UI_BACKUP_INTEGRITY="Checking ${UI_GRAVITY_NAME} backup integrity"
UI_BACKUP_INTEGRITY_FAILED='Integrity check has failed for the primary'
UI_BACKUP_INTEGRITY_DELETE='Removing failed backup'

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

# Purge
UI_PURGE_MATRIX_ALIGNMENT='Realigning dilithium crystal matrix'
UI_PURGE_DELETE_SSH_KEYS='Deleting SSH key-files'
UI_PURGE_CLEANING_DIR="Purging ${PROGRAM} directory"

# Automation
UI_AUTO_CRON_EXISTS='Automation task already exists in crontab'
UI_AUTO_CRON_DISPLAY_FREQ='Select synchronization frequency (in minutes)'
UI_AUTO_CRON_SELECT_FREQ='Valid options are 5, 10, 15, 30 or 0 to disable (default: 15)'
UI_AUTO_CRON_SAVING='Saving new synchronization task to crontab'
UI_AUTO_CRON_DISABLED='Synchronization automation has been disabled'

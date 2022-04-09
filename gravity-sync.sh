#!/usr/bin/env bash

# GRAVITY SYNC BY VMSTAN #####################
# GS 3.x to 4.0 Upgrade Utility ##############

# Run only to upgrade your existing Gravity Sync 3.x installation to 4.0 format
# This used to be the core of Gravity Sync, but that can now be invoked by running 'gravity-sync'

function upgrade_to_4 {
    echo -e "Upgrader"
}

# SCRIPT EXECUTION ###########################

case $# in
    0)
        upgrade_to_4 ;;
    1)
        case $1 in
            *)
            upgrade_to_4 ;;
        esac
    ;;
    
    *)
    upgrade_to_4 ;;
esac

# END OF SCRIPT ##############################
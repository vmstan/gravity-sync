#!/usr/bin/env bash

GS_LOCAL_REPO='/etc/gravity-sync/.gs'

    if [ -f "${GS_LOCAL_REPO}/dev" ]; then
        source ${GS_LOCAL_REPO}/dev
    else
        BRANCH='origin/master'
    fi
    
    if [ "$BRANCH" != "origin/master" ]; then
        echo -e "Pulling from ${BRANCH}"
    fi
    
    (cd ${GS_LOCAL_REPO}; sudo git fetch --all; sudo git reset --hard ${BRANCH}; sudo cp gravity-sync /usr/local/bin; sudo git clean -fq)


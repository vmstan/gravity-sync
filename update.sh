#!/usr/bin/env bash

GS_LOCAL_REPO='/etc/gravity-sync/.gs'

function update_gs {
    if [ -f "${GS_LOCAL_REPO}/dev" ]; then
        source ${GS_LOCAL_REPO}/dev
    else
        BRANCH='origin/master'
    fi
    
    if [ "$BRANCH" != "origin/master" ]; then
        echo -e "Pulling from ${BRANCH}"
    fi
    
    (cd ${GS_LOCAL_REPO}; git fetch --all; git reset --hard ${BRANCH}; sudo cp gravity-sync /usr/local/bin; git clean -fq)
}

update_gs
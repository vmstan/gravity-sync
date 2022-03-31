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
    
    GIT_CHECK=$(git status | awk '{print $1}')
    if [ "$GIT_CHECK" == "fatal:" ]; then
        echo -e "Updater usage requires GitHub installation"
        exit    
    else
        (cd ${GS_LOCAL_REPO}; git fetch --all; git reset --hard ${BRANCH}; sudo cp gravity-sync /usr/local/bin; git clean -fq)
    fi
}

update_gs
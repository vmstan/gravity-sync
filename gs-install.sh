#!/bin/bash

mkdir $HOME/gravity-sync
cd gravity-sync
git init
git remote add origin https://github.com/vmstan/gravity-sync.git
git fetch
git checkout origin/master -fr
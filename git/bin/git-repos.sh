#!/bin/bash

MAX_REPOS=400
curl -s https://api.github.com/orgs/progund/repos?per_page=$MAX_REPOS  > repos.json
REPOS=$(grep clone_url repos.json  | sed -e 's,"clone_url": ,,' -e "s/[,\"]//g" )
REPO_CNT=$(grep clone_url repos.json  | sed -e 's,"clone_url": ,,' -e "s/[,\"]//g"| wc -l )

if [ $REPO_CNT -ge $MAX_REPOS ]
then
    echo "ERROR ... max repos ($MAX_REPOS) reached"
    exit 1
fi
echo $REPOS

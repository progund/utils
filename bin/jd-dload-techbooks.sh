#!/bin/bash

#
#
# Bash script to download/update our books
#
#
#

THIS_SCRIPT_DIR=$(dirname $0)
THIS_SCRIPT=$0
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    . ${BASH_FUNCTIONS} $*
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

UTIL_REPO_ONLY=true
if [ "$1" = "--update-all" ]
then
    UTIL_REPO_ONLY=false
fi



clone_repo()
{
    do_exec "git clone $1" "clone repo $1"
}

update_repo()
{
    do_exec "git pull" "update repo in $(pwd)"
}

dload()
{
    REPO=$1
    REPO_DIR=$(echo $REPO|sed -e 's,https://github.com/progund/,,g' -e 's,.git,,g')
    if [ -d "$REPO_DIR" ]
    then
        pushd $REPO_DIR
        update_repo
        exit_on_error "$?" "Failed upgrading educational repository: $REPO_DIR"
        popd
    else
        clone_repo $REPO
        exit_on_error "$?" "Failed cloning educational repository: $REPO_DIR"
    fi
}

dload_repos()
{
    REPOS="$1"
    for repo in $REPOS
    do
        dload "$repo"
    done
}

dload_book()
{
    BOOK_DIR="$1"
    BOOK_REPOS="$2"
    mkdir -p $BOOK_DIR
    pushd $BOOK_DIR
    exit_on_error "$?" "Failed entering $BOOK_DIR"

    dload_repos "$BOOK_REPOS"

    popd
    exit_on_error "$?" "Failed getting back from $BOOK_DIR"
}


dload_c()
{
    # no extra dir needed for C
    dload_repos $C_REPOS
}

ORIG_DIR=$(pwd)
mkdir -p $DEST_DIR
cd $DEST_DIR
exit_on_error "$?" "Failed entering $DEST_DIR"

#
# Download/update books
#

if [ "$UTIL_REPO_ONLY" = "true" ]
then
    dload_repos "https://github.com/progund/utils.git"
    cd $ORIG_DIR
    $THIS_SCRIPT --update-all
    exit 0
else
    BOOKS_REPOS=utils/etc/books-repos.txt
    cat $BOOKS_REPOS | grep -v -e "^#" -v -e "^[ \t]*$" | while read book
    do
        DIR_NAME=$(echo $book | cut -d "|" -f 1)
        REPOS=$(echo $book | cut -d "|" -f 2)
        dload_book "$DIR_NAME" "$REPOS"
    done
#    dload_c
 #   dload_book "$JAVA_BOOK_DIR" "$JAVA_REPOS"
  #  dload_book "$DP_BOOK_DIR" "$DP_REPOS"
    #dload_book "$BASH_BOOK_DIR" "$BASH_REPOS"
   # dload_book "$MORE_BASH_BOOK_DIR" "$MORE_BASH_REPOS"
fi


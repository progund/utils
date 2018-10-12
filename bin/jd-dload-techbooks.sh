#!/bin/bash

#
#
# Bash script to download/update our books
#
#
#

THIS_SCRIPT_DIR="$(dirname $0)"
THIS_SCRIPT="$0"
BASH_FUNCTIONS="${THIS_SCRIPT_DIR}/bash-functions"
LOG_FILE=/tmp/jd-dload.log
if [ -f ${BASH_FUNCTIONS} ]
then
    . ${BASH_FUNCTIONS} $*
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

UTIL_REPO_ONLY=true
while [ "$1" != "" ]
do
    case "$1" in
        "--update-all")
            UTIL_REPO_ONLY=false
            ;;
        "--destination-dir")
            DEST_DIR="$2"
            shift
            ;;
        "--git")
            USE_GIT=true
            ;;
        "--all-repos")
            UTIL_REPO_ONLY=false
            ALL_REPOS=true
            ;;
        *)
            echo "SYNTAX ERROR: $1"
            exit 2
            ;;
    esac
    shift
done

log_to_file()
{
    if [ "$LOG_FILE" != "" ]
    then
        log "$*" >> $LOG_FILE
    fi           
}


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
        pushd "$REPO_DIR"
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
    echo "git_repos() $1" 
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
    mkdir -p "$BOOK_DIR"
    pushd "$BOOK_DIR"
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

ORIG_DIR="$(pwd)"
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"
exit_on_error "$?" "Failed entering $DEST_DIR"

dload_repo()
{
    repo=$1
    GIT_DIR=$(echo "$repo" | sed -e 's,https://github.com/progund/,,g' -e 's,.git,,g')
    log_to_file "        -- dir: $GIT_DIR"
    if [ -d $GIT_DIR ]
    then
        log_to_file "        -- updating repo ($repo)"
        pushd $GIT_DIR 2>/dev/null >/dev/null
        git pull
        RET=$?
        log_to_file "        -- pulling repo ${repo}: $RET"
        popd 2>/dev/null >/dev/null
        if [ $RET -ne 0 ]
        then
            log_to_file "        -- failed pulling repo ($repo), removing and cloning"
            rm -fr $GIT_DIR
            git clone "${repo}"
            RET=$?
            log_to_file "        -- cloning repo ${repo}: $?"
        fi              
    else
        log_to_file "        -- cloning repo ${repo}"
        git clone "${repo}"
            RET=$?
        log_to_file "        -- cloning repo ${repo}: $?"
    fi
    return $RET
}

dload_source_code()
{
    log_to_file "      --> dload_source_code()"
    curl -s https://api.github.com/orgs/progund/repos?per_page=400  > repos.json
    echo "\"clone_url\": \"https://git.savannah.nongnu.org/git/searduino.git\"" >> repos.json
    if [ "$USE_GIT" = "true" ]
    then
        REPOS=$(   grep ssh_url repos.json  | sed -e 's,"ssh_url": ,,' -e "s/[,\"]//g" )
        REPO_CNT=$(grep ssh_url repos.json  | sed -e 's,"ssh_url": ,,' -e "s/[,\"]//g"| wc -l )
    else
        REPOS=$(   grep clone_url repos.json  | sed -e 's,"clone_url": ,,' -e "s/[,\"]//g" )
        REPO_CNT=$(grep clone_url repos.json  | sed -e 's,"clone_url": ,,' -e "s/[,\"]//g"| wc -l )
    fi

    mkdir -p git
    pushd git 2>/dev/null >/dev/null

    log_to_file "        --> looping through repos"
    for repo in $REPOS
    do
        dload_repo $repo
    done
    log_to_file "        <-- looping through repos"

    popd 2>/dev/null >/dev/null
    log_to_file "      <-- dload_source_code()"
}


#
# Download/update books
#

if [ "$UTIL_REPO_ONLY" = "true" ]
then
    dload_repos "https://github.com/progund/utils.git"
    cd "$ORIG_DIR"
    $THIS_SCRIPT --update-all --destination-dir "$DEST_DIR"
    exit 0
elif [ "$ALL_REPOS" = "true" ]
then
    cd $DEST_DIR
    
    dload_source_code
    exit
else
    BOOKS_REPOS=utils/etc/books-repos.txt
    if [ ! -f $BOOKS_REPOS ]
    then
        echo "Can't find file: $BOOKS_REPOS"
        echo "Dest dir: $DEST_DIR"
        echo "Current dir: $(pwd)"
        exit 1
    fi
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

exit 0

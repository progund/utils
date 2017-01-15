#!/bin/bash

#
#
# Bash script to download/update our books
#
#
#

THIS_SCRIPT_DIR=$(dirname $0)
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


COMMON_REPOS="https://github.com/progund/computer-introduction.git https://github.com/progund/programming-introduction.git"

JAVA_REPOS="https://github.com/progund/control-flow.git \
 https://github.com/progund/our-first-java-program.git \
 https://github.com/progund/programming-in-java.git \
 https://github.com/progund/objects_in_java.git \
 https://github.com/progund/intro-java-assignment-1.git \
 https://github.com/progund/classes.git \
 https://github.com/progund/java-programming-assignment2-public.git \
 https://github.com/progund/inheritance.git \
 https://github.com/progund/interfaces.git \
 https://github.com/progund/exceptions.git"

C_REPOS="https://github.com/progund/programming-with-c.git"

BASH_REPOS=""

MORE_BASH_REPOS="https://github.com/progund/bash-script.git https://github.com/progund/bash-control-flow.git https://github.com/progund/bash-output-and-return.git"

DP_REPOS="https://github.com/progund/design_patterns_introduction.git \
 https://github.com/progund/design_patterns_builder.git \
 https://github.com/progund/design-patterns-bi-directional-builder.git \
 https://github.com/progund/design-patterns-singleton.git \
 https://github.com/progund/design-patterns-oo-design-principles.git \
 https://github.com/progund/design-patterns-factories.git \
 https://github.com/progund/design-patterns-decorator.git \
 https://github.com/progund/design-patterns-strategy.git \
 https://github.com/progund/design-patterns-observer.git \
 https://github.com/progund/java-surprises.git"


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


mkdir -p $DEST_DIR
cd $DEST_DIR
exit_on_error "$?" "Failed entering $DEST_DIR"

#
# Download/update books
#

if [ "$UTIL_REPO_ONLY" = "true" ]
then
    dload_repos "https://github.com/progund/utils.git"
    $0 --update-all
else
    dload_c
    dload_book "$JAVA_BOOK_DIR" "$JAVA_REPOS"
    dload_book "$DP_BOOK_DIR" "$DP_REPOS"
    #dload_book "$BASH_BOOK_DIR" "$BASH_REPOS"
    dload_book "$MORE_BASH_BOOK_DIR" "$MORE_BASH_REPOS"
fi


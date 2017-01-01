#!/bin/bash


THIS_SCRIPT_DIR=$(dirname $0)
BASH_FUNCTIONS=${THIS_SCRIPT_DIR}/bash-functions
if [ -f ${BASH_FUNCTIONS} ]
then
    echo "Sourcing file:  ${BASH_FUNCTIONS}"
    . ${BASH_FUNCTIONS}
else
    echo -n "Failed finding file: ${BASH_FUNCTIONS}. "
    echo "Bailing out..."
    exit 1
fi

source_file ${THIS_SCRIPT_DIR}/settings

${THIS_SCRIPT_DIR}/download-software.sh
exit_on_error "$?" "Failed downloading system software"

${THIS_SCRIPT_DIR}/dload-techbooks.sh
exit_on_error "$?" "Failed downloading juneday educational repositories"

sudo usermod -a -G dialout $USER

pushd ${THIS_SCRIPT_DIR}/../test
make check
exit_on_error "$?" "Failed verifying development softwares"
popd

${THIS_SCRIPT_DIR}/install-desktop-entries.sh
exit_on_error "$?" "Failed creating desktop entries"

${THIS_SCRIPT_DIR}/setup-user.sh
exit_on_error "$?" "Failed setting up stuff for user"

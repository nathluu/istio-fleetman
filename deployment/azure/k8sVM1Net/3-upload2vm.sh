#!/usr/bin/env sh
if [[ $# -lt 3 ]]; then
    echo "Illegal number of parameters"
fi
USER_NAME=$1
HOST=$2
WORK_DIR=$3

scp -i my_id_rsa -r $WORK_DIR $USER_NAME@$HOST:/home/$USER_NAME/
#!/bin/sh

set -e

if [[ -z ${SSH_USERNAME} ]]; then
    echo "SSH_USERNAME environment variable not set."
    exit -100  
fi

if [[ ! -f "/home/${SSH_USERNAME}/" ]]; then
    echo "home directory does't exist."
    exit -101  
fi

if [[ ! -f "/tmp/.ssh/authorized_keys" ]]; then
    echo "no authorized keys file found."
    exit -102  
fi

if [[ -z ${BACKUP_DESTINATION} ]]; then
    echo "BACKUP_DESTINATION environment variable not set."
    exit -103
fi


# copy and set permissions.
cp -R /tmp/.ssh /home/${SSH_USERNAME}/.ssh
chown -R ${SSH_USERNAME}:${SSH_USERNAME} /home/${SSH_USERNAME}/.ssh
chmod 700 /home/${SSH_USERNAME}/.ssh
chmod 600 /home/${SSH_USERNAME}/.ssh/authorized_keys
# chmod 644 /home/${SSH_USERNAME}/.ssh/id_rsa.pub
# chmod 600 /home/${SSH_USERNAME}/.ssh/id_rsa

# set permissions for backup dir
# TODOOOO: also find out what permissions

exec "$@"
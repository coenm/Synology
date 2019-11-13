#!/bin/bash

## #!/bin/sh

set -e

if [ -z ${SSH_USERNAME} ]; then
    echo "SSH_USERNAME environment variable not set."
    exit 100
fi

if [ -z ${UID} ]; then
    echo "UID environment variable not set."
    exit 103
fi

if [ -z ${GID} ]; then
    echo "GID environment variable not set."
    exit 104
fi

if [[ ! -d "/home/${SSH_USERNAME}/" ]]; then
    echo home directory /home/${SSH_USERNAME}/ does not exist!
    exit 101
fi

if [[ ! -f "/tmp/.ssh/authorized_keys" ]]; then
    echo "no authorized keys file found."
    exit 102
fi

if [[ -z ${BACKUP_DESTINATION} ]]; then
    echo "BACKUP_DESTINATION environment variable not set."
    exit 200
fi

userdel -f -r ${SSH_USERNAME}
groupadd -f -r -g ${GID} ${SSH_USERNAME}
useradd -ms /bin/bash -r -g ${SSH_USERNAME} -u ${UID} ${SSH_USERNAME}

# copy and set permissions.
mkdir -p /home/${SSH_USERNAME}/.ssh
cp /tmp/.ssh/authorized_keys /home/${SSH_USERNAME}/.ssh/
#cp -R /tmp/.ssh /home/${SSH_USERNAME}/.ssh
chown -R ${SSH_USERNAME}:${SSH_USERNAME} /home/${SSH_USERNAME}/.ssh
chmod 700 /home/${SSH_USERNAME}/.ssh
chmod 600 /home/${SSH_USERNAME}/.ssh/authorized_keys
# chmod 644 /home/${SSH_USERNAME}/.ssh/id_rsa.pub
# chmod 600 /home/${SSH_USERNAME}/.ssh/id_rsa


# Copy HostKeys when they are available. Otherwise, use existing ones.
if [[ -f "/tmp/.ssh/ssh_host_ed25519_key" && -f "/tmp/.ssh/ssh_host_ed25519_key.pub" ]]; then
    echo ssh_host_ed25519_key exists
    rm /etc/ssh/ssh_host_ed25519_key
    rm /etc/ssh/ssh_host_ed25519_key.pub
    cp /tmp/.ssh/ssh_host_ed25519_key /etc/ssh/
    cp /tmp/.ssh/ssh_host_ed25519_key.pub /etc/ssh/

    chmod 644 /etc/ssh/ssh_host_ed25519_key.pub
    chmod 600 /etc/ssh/ssh_host_ed25519_key
    echo done ed25519
fi

if [[ -f "/tmp/.ssh/ssh_host_rsa_key" && -f "/tmp/.ssh/ssh_host_rsa_key.pub" ]]; then
    echo ssh_host_rsa_key exists
    rm /etc/ssh/ssh_host_rsa_key
    rm /etc/ssh/ssh_host_rsa_key.pub
    cp /tmp/.ssh/ssh_host_rsa_key /etc/ssh/
    cp /tmp/.ssh/ssh_host_rsa_key.pub /etc/ssh/

    chmod 644 /etc/ssh/ssh_host_rsa_key.pub
    chmod 600 /etc/ssh/ssh_host_rsa_key
    echo done ssh_host_rsa_key
fi


# set permissions for backup dir
# TODOOOO: also find out what permissions

exec "$@"
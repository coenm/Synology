#!/bin/sh

set -e

# cp -R /tmp/.ssh /root/.ssh
# chmod 700 /root/.ssh
# chmod 644 /root/.ssh/id_rsa.pub
# chmod 600 /root/.ssh/id_rsa

cp -R /tmp/.ssh /home/dockerbackup/.ssh
chown -R dockerbackup:dockerbackup /home/dockerbackup/.ssh
chmod 700 /home/dockerbackup/.ssh
chmod 600 /home/dockerbackup/.ssh/authorized_keys

# chmod 644 /home/dockerbackup/.ssh/id_rsa.pub
# chmod 600 /home/dockerbackup/.ssh/id_rsa

exec "$@"
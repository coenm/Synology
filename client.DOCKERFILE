FROM ubuntu:18.04

LABEL maintainer="Coen van den Munckhof" \
  org.label-schema.name="Client" \
  org.label-schema.description="SSH Rsync backup client for Synology NAS" \
  org.label-schema.url="https://github.com/coenm/Synology" \
  org.label-schema.vcs-url="https://github.com/coenm/Synology" \
  org.label-schema.vendor="CoenM" \
  org.label-schema.schema-version="1.0"


ENV REFRESHED_AT 2019-11-11
ENV SSH_USERNAME dockerbackup

RUN apt-get -yqq update && \
    apt-get -yqq install ssh && \
    apt-get -yqq install rsync 

# ReadOnly permission
# Source for backup
VOLUME [ "/source" ]

# ReadOnly permission
# Should contain users private key, and public key of the host.
# For now, we don't check the HostKey (-o StrictHostKeyChecking=false) but for the next version
# this docker container will create a KnownHost file using the key (and address)
VOLUME [ "/tmp/.ssh/" ]

# ReadOnly permission
# Legacy: Contains configuration for backup.
VOLUME [ "/config" ]

# Read/Write permission
# Legacy: Backup process writes logs to this folder.
VOLUME [ "/logs" ]

# https://nickjanetakis.com/blog/docker-tip-56-volume-mounting-ssh-keys-into-a-docker-container
COPY ./backup /bin/backup
RUN chmod +x /bin/backup/backup.sh 

ENTRYPOINT ["/bin/backup/backup.sh"]
CMD ["-h"]


# https://github.com/moby/moby/issues/6396
# http://www.inanzzz.com/index.php/post/qdil/creating-a-ssh-server-with-openssh-by-using-docker-compose-and-connecting-to-it-with-php

# docker exec -ti server /bin/bash
# docker run -d -p 22222:22 --name server --mount type=bind,source="/c/Users/coen/docker/ssh/",target="/tmp/.ssh/",readonly --rm coenm/server:v1.9
# docker run -d -p 22222:22 --name server --mount type=bind,source="/c/Users/coen/docker/ssh/",target="/tmp/.ssh/",readonly --mount type=bind,source="/c/Users/coen/docker/backup/",target="/backup/" --rm coenm/server:v1.10

# docker run --name client --mount type=bind,source="/c/Users/coen/docker/ssh/",target="/tmp/.ssh/",readonly --mount type=bind,source="/c/Users/coen/docker/source/",target="/source/",readonly --rm coenm/client:1.0

# docker desktop
# docker run -d -p 22222:22 --name server --mount type=bind,source="D:/Docker/BackupServer/ssh/",target="/tmp/.ssh/",readonly --mount type=bind,source="D:/Docker/BackupServer/backup/",target="/backup/" --rm coenm/server:2.0
# docker run -d -p 22222:22 --name server --mount type=bind,source="/D/Docker/BackupServer/ssh/",target="/tmp/.ssh/",readonly --mount type=bind,source="/D/Docker/BackupServer/backup/",target="/backup/" --rm coenm/server:2.0


# docker run -ti --name ubuntu --mount type=bind,source="/D/Docker/UbuntuShare",target="/WindowsShare/" ubuntu:latest /bin/bash
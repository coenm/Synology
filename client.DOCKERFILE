FROM ubuntu:18.04

LABEL maintainer="Coen van den Munckhof" \
  org.label-schema.name="Client" \
  org.label-schema.description="SSH Rsync backup client for Synology NAS" \
  org.label-schema.url="https://github.com/coenm/Synology" \
  org.label-schema.vcs-url="https://github.com/coenm/Synology" \
  org.label-schema.vendor="CoenM" \
  org.label-schema.schema-version="1.0"


ENV REFRESHED_AT 2019-11-082
ENV SSH_USERNAME dockerbackup

RUN apt-get -yqq update && \
    apt-get -yqq install ssh && \
    apt-get -yqq install rsync 

# RUN mkdir /var/run/sshd

#RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# ADD sshd/fixed_sshd_config /etc/ssh/sshd_config

VOLUME [ "/source" ]
VOLUME [ "/tmp/.ssh/" ]


# https://nickjanetakis.com/blog/docker-tip-56-volume-mounting-ssh-keys-into-a-docker-container
COPY . /bin/backup
# RUN chmod +x /bin/backup/backup.sh 

# ENTRYPOINT ["/bin/backup/backup.sh"]
CMD ["bin/bash"]

# -o StrictHostKeyChecking=fals

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
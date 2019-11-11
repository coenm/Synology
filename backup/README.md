## Install

```
cd backups
chmod +x backup.sh
```


# Docker


## Network

```
docker network ls
docker network create rsync
docker network connect rsync client
docker network connect rsync server
```

## Client

```

docker build -t coenm/client:1.0 -f client.DOCKERFILE .

docker image rm coenm/client:1.0

docker run --name client --mount type=bind,source="/c/Users/coen/docker/ssh/",target="/tmp/.ssh/",readonly --mount type=bind,source="/c/Users/coen/docker/source/",target="/source/",readonly --mount type=bind,source="/c/Users/coen/docker/logs/",target="/logs/" --mount type=bind,source="/c/Users/coen/docker/config/",target="/config/",readonly --rm --network=rsync coenm/client:1.0 -s docker -d docker -p -v

docker container rm -f client

```



## Server

```
docker build -t coenm/server:1.0 .

docker image rm coenm/server:1.0

docker run -d -p 22222:22 --name server --mount type=bind,source="/c/Users/coen/docker/ssh/",target="/tmp/.ssh/",readonly --mount type=bind,source="/c/Users/coen/docker/backup/",target="/backup/" --rm coenm/server:1.0

```
# k0st/alpine-fir

Fast Incident Response (FIR) based on Alpine

Image is based on the [gliderlabs/alpine](https://registry.hub.docker.com/u/gliderlabs/alpine/) base image

## Docker image size

[![Latest](https://badge.imagelayers.io/k0st/alpine-fir.svg)](https://imagelayers.io/?images=k0st/alpine-fir:latest 'latest')

## Docker image usage

```
docker run [docker-options] k0st/alpine-fir
```

## Examples

Typical basic usage (using SQLite if databate is not linked): 

```
docker run -it k0st/alpine-fir
```

Typical usage with PostgreSQL:

```
docker run -d -e POSTGRES_USER=fir -e POSTGRES_PASSWORD=firpass -e POSTGRES_DB=fir --name=firdb k0st/alpine-postgres
docker run -it --name fir --link firdb:db k0st/alpine-fir

```

Typical usage with MySQL/MariaDB:

```
docker run -it -e MYSQL_USER=fir -e MYSQL_PASSWORD=firpass -e MYSQL_DATABASE=fir --name=firdb k0st/alpine-mariadb
docker run -it --name fir --link firdb:db k0st/alpine-fir
```

### Todo
- [ ] Perform more testing


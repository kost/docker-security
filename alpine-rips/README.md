# k0st/alpine-rips

Dockerized RIPS scanner - a static source code analyser for vulnerabilities in PHP scripts

RIPS - A static source code analyser for vulnerabilities in PHP scripts is available at:
http://rips-scanner.sourceforge.net/

Image is based on the [gliderlabs/alpine](https://registry.hub.docker.com/u/gliderlabs/alpine/) base image

## Docker image size

[![Latest](https://badge.imagelayers.io/k0st/alpine-rips.svg)](https://imagelayers.io/?images=k0st/alpine-rips:latest 'latest')

## Docker image usage

```
docker run --rm -it k0st/alpine-rips 
```

## Examples

Prepare to scan source from /path/to/host/source/files:
```
docker run --rm -it -v /path/to/host/source/files:/work:ro k0st/alpine-rips 
```

### Todo
- [ ] Check volume and data


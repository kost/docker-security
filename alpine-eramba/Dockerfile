FROM k0st/alpine-apache-php
MAINTAINER kost - https://github.com/kost

ENV VERSION_ERAMBA 204015

RUN apk --update add php-mysql php-pdo_mysql mysql-client && rm -f /var/cache/apk/* && \
curl https://s3.eu-central-1.amazonaws.com/dlh/eramba/eramba_$VERSION_ERAMBA.tgz -o /tmp/eramba_$VERSION_ERAMBA.tgz && \
tar -xvz -C /app -f /tmp/eramba_$VERSION_ERAMBA.tgz && \
rm -f /tmp/eramba_$VERSION_ERAMBA.tgz && \
mv /app/eramba_v2/* /app/ && \
mv /app/eramba_v2/.htaccess /app/ && \
rm -rf /app/eramba_v2/ && \
echo "Success"

ADD scripts/ /scripts


#!/bin/sh

# set -x

if [ "$SUBURI" == "" ]; then
	echo "[i] Using root (/) URI"
else
	echo "[i] Using suburi: $SUBURI"
	cat << EOF > /etc/apache2/conf.d/eramba.conf
Alias $SUBURI "/app/"

<Directory "/app">
    Options FollowSymLinks
    AllowOverride All
#    Require all granted
    Order allow,deny
    Allow from all
</Directory>

EOF
	grep ^DocumentRoot /etc/apache2/httpd.conf | grep -i /var/www/localhost/htdocs
	if [ "$?" != "0" ]; then
		sed -i 's#^DocumentRoot ".*#DocumentRoot "/var/www/localhost/htdocs"#g' /etc/apache2/httpd.conf
	fi

	grep RewriteBase /app/.htaccess 
	if [ "$?" != "0" ]; then
		sed -i "s#RewriteEngine on#RewriteEngine on\n\tRewriteBase ${SUBURI}#gi" /app/.htaccess
	else
		sed -i "s#RewriteBase.*#RewriteBase ${SUBURI}#gi" /app/.htaccess
	fi
	grep RewriteBase /app/app/.htaccess
	if [ "$?" != "0" ]; then
		sed -i "s#RewriteEngine on#RewriteEngine on\n\tRewriteBase ${SUBURI}#gi" /app/app/.htaccess
	else
		sed -i "s#RewriteBase.*#RewriteBase ${SUBURI}#gi" /app/app/.htaccess
	fi
	grep RewriteBase /app/app/webroot/.htaccess
	if [ "$?" != "0" ]; then
		sed -i "s#RewriteEngine on#RewriteEngine on\n\tRewriteBase ${SUBURI}#gi" /app/app/webroot/.htaccess
	else
		sed -i "s#RewriteBase.*#RewriteBase ${SUBURI}#gi" /app/app/webroot/.htaccess
	fi
fi


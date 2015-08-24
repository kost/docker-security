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

	for HTACCESS in /app/.htaccess /app/app/.htaccess /app/app/webroot/.htaccess
	do
		echo "[i] Configuring $HTACCESS"
		grep RewriteBase $HTACCESS
		if [ "$?" != "0" ]; then
			sed -i "s#RewriteEngine on#RewriteEngine on\n\tRewriteBase ${SUBURI}#gi" $HTACCESS
		else
			sed -i "s#RewriteBase.*#RewriteBase ${SUBURI}#gi" $HTACCESS
		fi
	done
fi


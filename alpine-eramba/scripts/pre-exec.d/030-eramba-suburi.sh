#!/bin/sh

# set -x

if [ -f "/app/app/Config/eramba.configured" ]; then
        exit 0
fi

ERAMBASUBCONF=/app/app/Config/eramba-suburi.configured

if [ -f "$ERAMBASUBCONF" ]; then
	echo "[i] SubURI already configured"
else
	echo "[i] Configuring SubURI"
if [ "$SUBURI" == "" ]; then
	echo "[i] Using root (/) URI"
else
	echo "[i] Using SubURI: $SUBURI"
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
	
	# configure suburi
	echo -e "\nConfigure::write('App.base', '$SUBURI');\n" >> /app/app/Config/core.php
fi # if [ "$SUBURI" == "" ]; then
	touch "$ERAMBASUBCONF"
fi # if [ -f "$ERAMBASUBCONF" ]; then


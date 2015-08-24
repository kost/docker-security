#!/bin/sh

# set -x

ERAMBADBCONF=/app/app/Config/database.php
MAXTRIES=20

if [ "$DB_ENV_MYSQL_PASSWORD" = "" ]; then
	DBPWOPT=
else
	DBPWOPT="-p$DB_ENV_MYSQL_PASSWORD"
fi

wait4mysql () {
echo "[i] Waiting for database to setup..."

for i in $(seq 1 1 $MAXTRIES)
do
	echo "[i] Trying to connect to database: try $i..."
	mysql -B --connect-timeout=1 -h db -u $DB_ENV_MYSQL_USER $DBPWOPT -e "SELECT VERSION();" $DB_ENV_MYSQL_DATABASE 

	if [ "$?" = "0" ]; then
		echo "[i] Successfully connected to database!"
		break
	else
		if [ "$i" = "$MAXTRIES" ]; then
			echo "[!] You need to have container for database. Take a look at docker-compose.yml file!"
			exit 0
		else
			sleep 5
		fi
	fi
done
}

check4mysql () {
	echo "[i] Checking if database is empty..."
	LISTTABLES=`(mysql -B -h db -u $DB_ENV_MYSQL_USER $DBPWOPT -e "SHOW TABLES;" $DB_ENV_MYSQL_DATABASE )`
	if [ "$?" = "0" ]; then
		NUMTABLES=`( echo "$LISTTABLES" | wc -l )`
		echo "Tables: $NUMTABLES"
		if [ "$NUMTABLES" = "1" ]; then
			echo "[i] Looks like database is empty!"			
			return 1
		fi
	else
		echo "[i] Error connecting to database. Exiting"
		exit 1	
	fi
	return 0
}
		
wait4mysql
DBEMPTY=$( check4mysql )

if [ -f "$ERAMBADBCONF" ]; then
	echo "[i] Found database configuration. Not touching it!"
else
	echo "[i] Database configuration missing. Creating..."
	
	cat << EOF > $ERAMBADBCONF
<?php

class DATABASE_CONFIG {

        public \$default = array(
                'datasource' => 'Database/Mysql',
                'persistent' => false,
                'host' => 'db',
                'login' => '$DB_ENV_MYSQL_USER',
                'password' => '$DB_ENV_MYSQL_PASSWORD',
                'database' => '$DB_ENV_MYSQL_DATABASE',
                'prefix' => '',
                'encoding' => 'utf8',
        );

}
EOF

	if [ "$DBEMPTY" = "1" ]; then	
		echo "[i] Creating initial schema..."
		cat  /app/app/Config/db_schema/latest.sql | mysql -h db -u $DB_ENV_MYSQL_USER $DBPWOPT $DB_ENV_MYSQL_DATABASE
	else
		echo "[i] Database not empty. Not touching it!"
	fi	
fi


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

if [ "$DEBUG" = "" ]; then
	sed -i "s#Configure::write('debug',.*)#Configure::write('debug',0)#g" /app/app/Config/core.php
fi


#!/bin/sh

if [ "$DEBUG" != "" ]; then
	set -x 
fi

MAXTRIES=20

APPDIR=/app/fir
CONFFILE=$APPDIR/fir/config/production.py
CONFSWITCH='--settings fir.config.production'
export DJANGO_SETTINGS_MODULE=fir.config.production

# execute any pre-init scripts, useful for images
# based on this image
for i in /scripts/pre-init.d/*sh
do
	if [ -e "${i}" ]; then
		echo "[i] pre-init.d - processing $i"
		. "${i}"
	fi
done

wait4mysql () {
echo "[i] Waiting for database to setup..."

for i in $(seq 1 1 $MAXTRIES)
do
	echo "[i] Trying to connect to database: try $i..."
	if [ "$DB_ENV_MYSQL_PASSWORD" = "" ]; then
		mysql -B --connect-timeout=1 -h db -u $DB_ENV_MYSQL_USER -e "SELECT VERSION();" $DB_ENV_MYSQL_DATABASE 
	else
		mysql -B --connect-timeout=1 -h db -u $DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASSWORD -e "SELECT VERSION();" $DB_ENV_MYSQL_DATABASE 
	fi

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

wait4psql () {
echo "[i] Waiting for database to setup..."

export PGPASSWORD=$DB_ENV_POSTGRES_PASSWORD
for i in $(seq 1 1 $MAXTRIES)
do
	echo "[i] Trying to connect to database: try $i..."
	psql -h db -U $DB_ENV_POSTGRES_USER -d $DB_ENV_POSTGRES_DB -w -c 'SELECT version();'
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

dbheader () {
	echo "DATABASES = {" >> $CONFFILE
	echo "    'default': {" >> $CONFFILE
}

dbfooter () {
	echo "    }" >> $CONFFILE
	echo "}" >> $CONFFILE
}

echo "[i] Syncing database"

if [ -f /app/db.initialized ]; then
	echo "Database initialized. Not doing anything."
	if [ "$DB_ENV_MYSQL_USER" != "" ]; then
		wait4mysql
	fi
	if [ "$DB_ENV_POSTGRES_USER" != "" ]; then
		wait4psql
	fi
	gosu app /app/fir/manage.py migrate $CONFSWITCH
else 
	echo "Initializing config and database."	

	if [ "$DEBUG" = "" ]; then
		echo "[i] Disabling debugging"
	else
		echo "[i] Enabling debugging"
		echo "DEBUG = True" >> $CONFFILE
		echo "TEMPLATE_DEBUG = DEBUG" >> $CONFFILE
	fi

	if [ "$ALLOWEDHOSTS" = "" ]; then
		echo "ALLOWED_HOSTS = ['*']" >> $CONFFILE
	else
		echo "ALLOWED_HOSTS = ['$ALLOWEDHOSTS']" >> $CONFFILE
	fi

	if [ "$MAILHOST" = "" ]; then
		echo "EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'" >> $CONFFILE
	else
		echo "EMAIL_HOST = '$MAILHOST'" >> $CONFFILE
		echo "EMAIL_PORT = 25" >> $CONFFILE
	fi

	FOUND_DB=0
	if [ "$DB_ENV_MYSQL_USER" != "" ]; then
		echo "[i] Found MySQL setup"
		dbheader
		echo "        'ENGINE': 'django.db.backends.mysql'," >> $CONFFILE
		echo "        'NAME': '$DB_ENV_MYSQL_DATABASE'," >> $CONFFILE
		echo "        'USER': '$DB_ENV_MYSQL_USER'," >> $CONFFILE
		echo "        'PASSWORD': '$DB_ENV_MYSQL_PASSWORD'," >> $CONFFILE
		echo "        'HOST': 'db'," >> $CONFFILE
		echo "        'PORT': ''," >> $CONFFILE
		dbfooter
		FOUND_DB=1
		wait4mysql
	fi

	if [ "$DB_ENV_POSTGRES_USER" != "" ]; then
		echo "[i] Found PostgreSQL setup"
		dbheader
		echo "        'ENGINE': 'django.db.backends.postgresql_psycopg2'," >> $CONFFILE
		echo "        'NAME': '$DB_ENV_POSTGRES_DB'," >> $CONFFILE
		echo "        'USER': '$DB_ENV_POSTGRES_USER'," >> $CONFFILE
		echo "        'PASSWORD': '$DB_ENV_POSTGRES_PASSWORD'," >> $CONFFILE
		echo "        'HOST': 'db'," >> $CONFFILE
		echo "        'PORT': ''," >> $CONFFILE
		dbfooter
		FOUND_DB=1
		wait4psql
	fi

	if [ "$FOUND_DB" = "0" ]; then
		echo "[i] Container not linked with DB. Using SQLite."
		dbheader
		echo "        'ENGINE': 'django.db.backends.sqlite3'," >> $CONFFILE
		echo "        'NAME': '/data/db.sqlite3'," >> $CONFFILE
		dbfooter
	fi

	for i in /scripts/pre-initdb.d/*sh
	do
		if [ -e "${i}" ]; then
			echo "[i] pre-initdb.d - processing $i"
			. "${i}"
		fi
	done

	echo "[i] Initializing database"
	cd $APPDIR
	gosu app $APPDIR/manage.py syncdb --noinput $CONFSWITCH
	gosu app $APPDIR/manage.py migrate $CONFSWITCH
	
	if [ "$DEMO" = "" ]; then
		gosu app echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'admin')" | python manage.py shell $CONFSWITCH
	else
		gosu app $APPDIR/manage.py loaddata incidents/fixtures/seed_data.json $CONFSWITCH
		gosu app /app/fir/manage.py loaddata incidents/fixtures/dev_users.json $CONFSWITCH
	fi
	gosu app /app/fir/manage.py collectstatic --noinput $CONFSWITCH
	touch /app/db.initialized

	for i in /scripts/post-initdb.d/*sh
	do
		if [ -e "${i}" ]; then
			echo "[i] post-initdb.d - processing $i"
			. "${i}"
		fi
	done
fi


echo "[i] Starting application using supervisor"
supervisord -c /etc/supervisord.conf
# supervisorctl start app

# display logs
tail -F /var/log/gunicorn_supervisor.log /var/log/supervisord.log /var/log/nginx/access.log /var/log/nginx/error.log &

# execute any pre-exec scripts, useful for images
# based on this image
for i in /scripts/pre-exec.d/*sh
do
	if [ -e "${i}" ]; then
		echo "[i] pre-exec.d - processing $i"
		. "${i}"
	fi
done

echo "[i] Starting daemon..."
# run daemon
nginx -g "daemon off;"

killall tail

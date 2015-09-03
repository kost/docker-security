#!/bin/sh

NAME="fir"					# Name of the application
DJANGODIR=/app/fir				# Django project directory
SOCKFILE=/app/run/gunicorn.sock			# we will communicte using this unix socket
USER=app					# the user to run as
GROUP=app					# the group to run as
NUM_WORKERS=3					# how many worker processes should Gunicorn spawn
# DJANGO_SETTINGS_MODULE=fir.settings		# which settings file should Django use
DJANGO_SETTINGS_MODULE=fir.config.production	# which settings file should Django use
DJANGO_WSGI_MODULE=wsgi				# WSGI module name

echo "Starting $NAME as `whoami`"

cd $DJANGODIR

# Create the run directory if it doesn't exist
RUNDIR=$(dirname $SOCKFILE)
test -d $RUNDIR || mkdir -p $RUNDIR

# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --workers $NUM_WORKERS \
  --user=$USER --group=$GROUP \
  --bind=unix:$SOCKFILE \
  --log-level=info \
  --log-file=-

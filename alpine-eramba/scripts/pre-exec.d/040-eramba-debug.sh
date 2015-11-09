#!/bin/sh

# set -x

if [ -f "/app/app/Config/eramba.configured" ]; then
        exit 0
fi

ERAMBADEBUGCONF=/app/app/Config/eramba-debug.configured

if [ -f "$ERAMBADEBUGCONF" ]; then
	echo "[i] Eramba already configured"
else
	echo "[i] Configuring eramba config"
	touch "$ERAMBADEBUGCONF"

	if [ "$DEBUG" = "" ]; then
		sed -i "s#Configure::write('debug',.*)#Configure::write('debug',0)#g" /app/app/Config/core.php
	fi

fi


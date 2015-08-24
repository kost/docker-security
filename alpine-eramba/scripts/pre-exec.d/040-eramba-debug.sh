#!/bin/sh

# set -x

if [ "$DEBUG" = "" ]; then
	sed -i "s#Configure::write('debug',.*)#Configure::write('debug',0)#g" /app/app/Config/core.php
fi


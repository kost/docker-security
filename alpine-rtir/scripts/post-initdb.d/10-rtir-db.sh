#!/bin/sh

echo "[i] Initializing rtir db"
#cd /opt/RT-IR-$RTIR_VERSION
#make initialize-database
cd /opt/rt4
/usr/bin/perl -Ilib -I/opt/rt4/local/lib -I/opt/rt4/lib /opt/rt4/sbin/rt-setup-database --action insert --datadir local/plugins/RT-IR/etc --datafile local/plugins/RT-IR/etc/initialdata --package RT::IR --ext-version $RTIR_VERSION --skip-create
echo "[i] Finished initializing rtir db"


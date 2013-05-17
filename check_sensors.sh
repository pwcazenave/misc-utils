#!/bin/bash

# Script to spit out temperatures to a log file.
# Pierre Cazenave <pwcazenave <at> gmail <dot> com>
# Added support for the temper USB thermometer too.

PATH=/bin:/usr/bin/

set -eu

DATE=$(date "+%Y%m%d")
TIME=$(date "+%H%M%S")
LOGFILE=$HOME/logs/sensors/$(hostname)/temp.log
#TEMPERFILE=$HOMElogs/sensors/$(hostname)/temper.log

TEMP1=$(sensors -u | awk '/temp1_input/ {print $2}')
TEMP2=$(sensors -u | awk '/temp2_input/ {print $2}')
#TEMP3=$(temper | awk '/temperature/ {print $3}' | tr -d "C")
if [ ! -d ${LOGFILE%/*} ]; then
	mkdir -p ${LOGFILE%/*}
fi
#if [ ! -d ${TEMPERFILE%/*} ]; then
#	mkdir -p ${TEMPERFILE%/*}
#fi

echo $DATE $TIME $TEMP1 $TEMP2 >> $LOGFILE
#echo $DATE $TIME $TEMP3 >> $TEMPERFILE

exit 0

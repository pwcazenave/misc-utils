#!/bin/bash

# Run this with crontab at midnight to organise the previous day's webcam
# snapshots into dated subfolders.

BASE=/media/Archive/camera/

TODAY=${TODAY:-$(date "+%Y-%m-%d")}
ALTTODAY=${ALTTODAY:-$(date "+%Y%m%d")}

if [ ! -d $BASE/$TODAY ]; then
    mkdir $BASE/$TODAY
fi

mv $BASE/78A5DD003664\(003abjn\)_?_${ALTTODAY}*.jpg $BASE/$TODAY

# Tidy up any stragglers from yesterday (or any other day).
for i in $(ls -1 $BASE | grep -v -- - | grep -v $ALTTODAY); do 
    TODIR=$(echo $i | awk 'OFS="-" {print substr($0,25,4), substr($0,29,2), substr($0,31,2)}')
    if [ ! -d $TODIR ]; then
        mkdir $TODIR
        mv "$i" $TODIR
    fi
done

#!/bin/bash

# Run this with crontab at midnight to organise the previous day's webcam
# snapshots into dated subfolders.

BASE=/media/Archive/

TODAY=${TODAY:-$(date "+%Y-%m-%d")}
ALTTODAY=${ALTTODAY:-$(date "+%Y%m%d")}

if [ ! -d $BASE/$TODAY ]; then
    mkdir $BASE/$TODAY
fi

mv $BASE/78A5DD003664\(003abjn\)_?_${ALTTODAY}*.jpg $BASE/$TODAY || true

# Tidy up any stragglers from yesterday (or any other day).
for i in $(ls -1 $BASE | grep -v -- - | grep -v $ALTTODAY | awk 'OFS="-" {print substr($0,25,4), substr($0,29,2), substr($0,31,2)}' | sort -u); do 
    TODIR=$i
    if [ ! -d $BASE/$TODIR ]; then
        mkdir $BASE/$TODIR
        mv $BASE/78A5DD003664\(003abjn\)_?_${TODIR//-/}*.jpg $BASE/$TODIR
    fi
done

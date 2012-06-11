#!/bin/bash

set -e

OLDIFS=$IFS
IFS="
"

# Copy media to their final resting place.
cwd=$(pwd)
prefix=${prefix:-/Volumes/Photos/}

if [ ! -d ${prefix} ]; then
    echo "${prefix} does not appear to exist. Check your path and try again."
    exit 1
fi

if [ $# -ne 0 ]; then
   files=("$@")
else
   files=($(ls *.JPG *.NEF || true))
fi

for ((i=0; i<"${#files[@]}"; i++)); do
   year=($(stat -x -t "%Y" "${files[i]}" | sed -n '6p' | cut -f2 -d\  ))
   month=($(stat -x -t "%m" "${files[i]}" | sed -n '6p' | cut -f2 -d\  ))
   day=($(stat -x -t "%d" "${files[i]}" | sed -n '6p' | cut -f2 -d\  ))
   if [ ! -d $prefix/$year/$month*/$year-$month-$day ]; then
      cd $prefix/$year/$month*/
      mkdir $year-$month-$day
      cd ~-
   fi
   if [ ! -f $prefix/$year/$month*/$year-$month-$day/"${files[i]}" ]; then
      echo -n "Copying ${files[i]}... "
      cp -an "${files[i]}" $prefix/$year/$month*/$year-$month-$day/
      echo "done."
   else
      echo "Skipping ${files[i]}"
   fi
done

IFS=$OLDIFS

#!/usr/bin/env bash

conf=`php -i | grep -o "Scan this dir for additional .ini files => \S*" | cut -d\  -f9`

if [ -n $conf ]
then
  if !([ -h "$conf/20-yenc.ini" ] || [ -f "$conf/20-yenc.ini" ])
  then
    major=`php -r "echo PHP_VERSION;" | cut -d. -f1`
    minor=`php -r "echo PHP_VERSION;" | cut -d. -f2`
    phpver="$major.$minor"

    echo "Creating symlink for configuration file.";
    ln -s /etc/php/$phpver/mods-available/yenc.ini $conf/20-yenc.ini
  fi
else
  echo "Couldn't find additional .ini file directory. You will have to manually set your module configuration."
fi

#!/usr/bin/env bash

conf=`php -i | grep -o "Scan this dir for additional .ini files => \S*" | cut -d\  -f9`
major=`php -r "echo PHP_VERSION;" | cut -d. -f1`
minor=`php -r "echo PHP_VERSION;" | cut -d. -f2`
phpver="$major.$minor"

fpm -s dir -t deb \
    -n php$phpver-yenc -v 1.3.0 \
    --depends "php > ${phpver}" \
    --description "php-yenc extension build for PHP ${phpver}" \
    --url 'https://github.com/niel/php-yenc' \
    --after-install=post-install.sh \
     /etc/php/$phpver/mods-available/yenc.ini \
     $conf/20-yenc.ini \
     $(php-config  --extension-dir)/yenc.so

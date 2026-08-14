#!/bin/sh
# Every APP_* variable becomes a key in window.__CONFIG__: APP_API_URL -> API_URL.
set -eu

{
    echo 'window.__CONFIG__ = {'
    env | grep '^APP_' | sort | sed 's/^APP_\([^=]*\)=\(.*\)$/  \1: "\2",/'
    echo '}'
} > /usr/share/nginx/html/config.js

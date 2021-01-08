#!/bin/sh
# export $(cat .env | xargs)
#MY_VAR=$(grep MY_VAR .env | xargs)
case "$1" in
  up)
    type docker-compose >/dev/null 2>&1 || { echo >&2 "docker-compose is required but it's not installed.  Aborting."; exit 1; }
    docker-compose build && docker-compose up
    ;;
*)
    echo "Usage: service.sh {up}" >&2
    exit 1
    ;;
esac

exit 0
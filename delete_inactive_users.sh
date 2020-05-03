#!/usr/bin/env bash

if [ "$UID" -ne 0 ]; then
    echo "root priveledges required to run this script"
    exec  sudo "$0" "$@"
    exit 1
fi

if [ "$#" -ne 2 ]; then
    printf "Too few arguments ($#), expected 3.\nUsage: $0 INACTIVE_DAYS GROUP\n" >&2
    exit 1
fi

INACTIVE_DAYS=$1
GROUP=$2

REGEX='^[0-9]+$'
if ! [[ $INACTIVE_DAYS =~ $REGEX ]] ; then
    echo "error: Not a number" >&2;
    exit 1
fi

if [ -z $(getent group $GROUP) ]; then
    echo "group $GROUP does not exist."
    exit 1
fi

if ! [ -z $(id -u $GROUP 2>/dev/null) ]; then
    echo "group $GROUP does not exist. It is a user name." >&2
    exit 1
fi

INACTIVE_USERS=$(./see_logged_users.sh -ln --group=$GROUP -t $INACTIVE_DAYS | awk '{print $2}' | tail -n +2)

echo "Affected Users:"
for USER in $INACTIVE_USERS; do
    echo "$USER"
done

read -r -p "Are you sure? [y/N]:" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    for USER in $INACTIVE_USERS; do
	echo "deleting $USER"
	userdel -r $USER
	groupdel $USER
    done
    echo "done"
else
    echo "phew"
fi

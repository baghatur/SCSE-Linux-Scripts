#!/usr/bin/env bash

if [ "$UID" -ne 0 ]; then
    echo "root priveledges required to run this script" >&2
    exec  sudo "$0" "$@"
    exit 1
fi

if [ "$#" -ne 3 ]; then
    printf "Too few arguments ($#), expected 3.\nUsage: $0 FILE DEFAULT_PWD GROUP\n" >&2
    exit 1
fi

FILE=$1
DEFAULT_PWD=$2
GROUP=$3

if [ ! -f "$FILE" ]; then
    echo "File not found!" >&2
    exit 1
fi

if [ -z $(getent group $GROUP) ]; then
    echo "group $GROUP does not exist." >&2
    exit 1
fi

if ! [ -z $(id -u $GROUP 2>/dev/null) ]; then
    echo "group $GROUP does not exist. It is a user name." >&2
    exit 1
fi

while IFS=, read -r name surname username email ; do
    echo "Creating new user"
    echo "  -------------  "
    echo "Name     : $name"
    echo "Surname  : $surname"
    echo "Username : $username"
    echo "Email    : $email"
    echo ""

    if id "$username" > /dev/null 2>&1; then
        echo "Username $username already exists"
    else
        echo "Username $username does not exist. Creating new user."
	useradd -m -c "$name $surname $email" $username
	
	echo "Adding $username to $GROUP"
	usermod -a -G $GROUP $username

	echo "Changing $username password to default"
	echo "$DEFAULT_PWD" | passwd --stdin $username

	echo "Expire $username password forcing him to change password"
	passwd --expire $username
    fi
    
    echo ""

done < $FILE

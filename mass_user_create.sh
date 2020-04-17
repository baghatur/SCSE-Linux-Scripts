#!/usr/bin/env bash

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

if ! grep -q $GROUP /etc/group; then
    echo "group $GROUP does not exist"
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

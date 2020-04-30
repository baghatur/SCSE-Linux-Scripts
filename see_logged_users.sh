#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    printf "Too few arguments ($#), expected 1.\nUsage: $0 GROUP\n" >&2
    exit 1
fi

GROUP=$1
if ! grep -q $GROUP /etc/group; then
    echo "group $GROUP does not exist"
    exit 1
fi

USERS_SORTED=$(grep "$GROUP" /etc/group | sed 's/.*://;s/,/\n/g' | sort | uniq)
LOGGED_SORTED=$(last -w | awk '{print $1}' | sort | uniq | sed '/^$/d')

echo "Users in group $GROUP that have never logged in"
comm -23 <(echo "$USERS_SORTED") <(echo "$LOGGED_SORTED")

echo -e "\n------\n"

echo "Users in group $GROUP last logged in"
for USER in $(comm -12 <(echo "$USERS_SORTED" ) <(echo "$LOGGED_SORTED")); do
    last "$USER" | head -n 1 | awk '{print $1"\t\t"$(NF-5)" "$(NF-4)" "$(NF-3)" "$(NF-2)" "$(NF-1)" "$(NF)}'
done

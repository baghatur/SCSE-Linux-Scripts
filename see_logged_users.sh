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

LONGEST_USERNAME=$(awk '{print length}' <(echo "$USERS_SORTED") | sort -nr | head -1)

#echo "Users in group $GROUP that have never logged in"
#comm -23 <(echo "$USERS_SORTED") <(echo "$LOGGED_SORTED")

for USER in $(comm -12 <(echo "$USERS_SORTED" ) <(echo "$LOGGED_SORTED")); do
    TMP="${TMP}\n$(
    last -w "$USER" | head -n 1 |
    awk '{
    printf("| %'$LONGEST_USERNAME'-s | %3s %02d %s | %7-s |",$1, $5, $6, $7, $10)
    }')"
done

TMP="| USERNAME            | LAST LOGGED  | DURATION|
$(sort -k4Mr,4 -k5nr,5 <(echo -e "$TMP"))"

echo -e "$TMP"

#print $1"\t\t"$(NF-5)" "$(NF-4)" "$(NF-3)" "$(NF-2)" "$(NF-1)" "$(NF)

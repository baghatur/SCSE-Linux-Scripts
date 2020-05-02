#!/usr/bin/env bash

SHOW_LOGGED=0
SHOW_NEVER_LOGGED=0

function args()
{
    options=$(getopt -o lng: --long logged --long never-logged --long group: -- "$@")
    [ $? -eq 0 ] || {
        echo "Incorrect option provided"
        exit 1
    }
    eval set -- "$options"
    while true; do
        case "$1" in
        -l)
            ;&
        --logged)
            SHOW_LOGGED=1
            ;;
        -n)
            ;&
        --never-logged)
            SHOW_NEVER_LOGGED=1
            ;;
	-g)
	    ;&
	--group)
	    shift;
            GROUP=$1
	    ;;
	--)
	    shift
            break
            ;;
        esac
        shift
    done
}
 
args $0 "$@"

if [ -z ${GROUP+x} ]; then
    echo "Group is not set."
    exit 1
fi

if [ -z $(getent group $GROUP) ]; then
    echo "group $GROUP does not exist."
    exit 1
fi

if ! [ -z $(id -u $GROUP 2>/dev/null) ]; then
    echo "group $GROUP does not exist. It is a user name."
    exit 1
fi

USERS_SORTED=$(getent group $GROUP | sed 's/.*://;s/,/\n/g' | sort | uniq)
LOGGED_SORTED=$(last -w | awk '{print $1}' | sort | uniq | sed '/^$/d')

LONGEST_USERNAME=$(awk '{print length}' <(echo "$USERS_SORTED") | sort -nr | head -1)

for USER in $(comm -23 <(echo "$USERS_SORTED" ) <(echo "$LOGGED_SORTED")); do
    NEV="${NEV}\n$(
    awk '{
    printf("| %'$LONGEST_USERNAME'-s | --- -- --:-- | ------- |",$1)
    }' <(echo $USER))"
done

if [ "$SHOW_NEVER_LOGGED" -eq "1" ]; then
    NEV="| USERNAME            | LAST LOGGED  | DURATION|$NEV"
    echo -e "$NEV"
fi


for USER in $(comm -12 <(echo "$USERS_SORTED" ) <(echo "$LOGGED_SORTED")); do
    LOG="${LOG}\n$(
    last -w "$USER" | head -n 1 |
    awk '{
    printf("| %'$LONGEST_USERNAME'-s | %3s %02d %s | %7-s |",$1, $5, $6, $7, $10)
    }')"
done

if [ "$SHOW_LOGGED" -eq "1" ]; then
    LOG="| USERNAME            | LAST LOGGED  | DURATION|\n$(sort -k4Mr,4 -k5nr,5 <(echo -e "$LOG"))"
    echo -e "$LOG"
fi

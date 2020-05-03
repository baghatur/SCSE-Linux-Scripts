#!/usr/bin/env bash

SHOW_LOGGED=0
SHOW_NEVER_LOGGED=0
LOG_STARTING=9999
LOG_END=0

function args()
{
    options=$(getopt -o lng:f:t: --long logged --long never-logged --long group: --long from: --long to: -- "$@")
    [ $? -eq 0 ] || {
        echo "Incorrect option provided" >&2
        exit 1
    }
    eval set -- "$options"
    while true; do
        case "$1" in
        -l) ;& --logged)
            SHOW_LOGGED=1
            ;;
        -n) ;& --never-logged)
            SHOW_NEVER_LOGGED=1
            ;;
	-g) ;& --group)
	    shift;
            GROUP=$1
	    ;;
	-f) ;& --from)
	    shift;
	    LOG_STARTING=$1
	    ;;
	-t) ;& --to)
	    shift;
	    LOG_END=$1
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
    echo "Group is not set." >&2
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

USERS_SORTED=$(getent group $GROUP | sed 's/.*://;s/,/\n/g' | sort | uniq)
LOGGED_SORTED=$(last -w | awk '{print $1}' | sort | uniq | sed '/^$/d')

LONGEST_USERNAME=$(awk '{print length}' <(echo "$USERS_SORTED") | sort -nr | head -1)

for USER in $(comm -23 <(echo "$USERS_SORTED" ) <(echo "$LOGGED_SORTED")); do
    NEV="${NEV}$(
    awk '{
    printf("| %'$LONGEST_USERNAME'-s | --- -- --:--:-- |",$1)
    }' <(echo $USER))\n"
done
 
for USER in $(comm -12 <(echo "$USERS_SORTED" ) <(echo "$LOGGED_SORTED")); do
    LOG="${LOG}\n$(
    lastlog -u $USER -t $LOG_STARTING -b $LOG_END | tail -n -1 |
    awk '{
    printf("| %'$LONGEST_USERNAME'-s | %3s %02d %s |",$1, $5, $6, $7)
    }')"
done

if [ "$SHOW_LOGGED" -eq "1" ] || [ "$SHOW_NEVER_LOGGED" -eq "1" ]; then
    echo -e "| USERNAME            | LAST LOGGED IN  |"
fi
   
if [ "$SHOW_LOGGED" -eq "1" ]; then
    LOG="$(sort -k4Mr,4 -k5r,6 <(echo -e "$LOG"))"
    echo -e "$LOG"
fi

if [ "$SHOW_NEVER_LOGGED" -eq "1" ]; then
    echo -e "$NEV"
fi

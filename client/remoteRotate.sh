#!/bin/bash

settingsFile=$(dirname $0)/settings
dryRun=0
rotateAsCopy=1

function usage(){
    echo "$0 [-s settingsFile=settings] [-d] [-t toDepth] [-n maxAtDepth] [-m]" 
}

#options
while [ $# -gt 0 ]
do
    case $1
    in
        -s)
            settingsFile=$2
            shift 1
        ;;
        -t)
            toDepth=$2
            shift 1
        ;;
        -n)
            maxAtDepth=$2
            shift 1
        ;;
        -d)
            dryRun=1
        ;;
        -m)
            rotateAsCopy=0
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "no match: $1"
            usage
            exit 1
        ;;
    esac
    shift 1
done

. $settingsFile

if [ "$toDepth" = "" -o "$maxAtDepth" = "" ]
then
    usage
    exit 1
fi

if [ $dryRun -eq 0 ]
then
    rotateCmd='ssh'
else
    rotateCmd='echo "ssh"'
fi

rotateArgs="$REMOTE_BACKUP_USER@$REMOTE_SERVER -i $LOCAL_SSH_KEY \
    \"sudo /home/$REMOTE_BACKUP_USER/rsync-incremental/server/rotate.sh \
    $REMOTE_SITE_ROOT $toDepth $maxAtDepth $rotateAsCopy\""

eval "$rotateCmd $rotateArgs"

#!/bin/bash

#default label for this backup
LABEL=$(date +%Y-%m-%d-%H%M)

#defaults
settingsFile=settings
dryRun=0

function usage(){
    echo "$0 [-s settingsFile=settings] [-l label ] [-d] [-h]"
    echo "  -s settingsFile:  use settingsFile for variable definitions."
    echo "  -d : dry run, echo commands but do not execute"
    echo "  -h : help, print this usage information"
    echo "  -l label: force the label of this backup to label"
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
        -d)
            dryRun=1
        ;;
        -h)
            usage
            exit 0
        ;;
        -l)
            LABEL=$2
            shift 1
        ;;
        *)
            echo "no match: $1"
            usage
            exit 1
        ;;
    esac
    shift 1
done

. settings

REMOTE_NEW=$REMOTE_INCREMENTAL/$LABEL
nonEmptyVars=(SITE LOCAL_BACKUP_USER REMOTE_BACKUP_USER REMOTE_SERVER REMOTE_BACKUP_DIR REMOTE_BACKUP_DIR_IS_RELATIVE BACKUP_LIST)
valid=1
for varName in ${nonEmptyVars[*]}
do
    if [ "" == "${!varName}" ]
    then 
        echo "$varName not set. Please verify in settings file (filename: $settingsFile)."
        valid=0
    fi
done

if [ $valid -eq 0 ]
then
    echo "Exiting due to invalid settings"
    exit 1
fi

echo "START $LABEL"
#echo "sudo rsync -e \"ssh -i $LOCAL_SSH_KEY\" -avRz --link-dest $REMOTE_CUR $BACKUP_LIST $REMOTE_BACKUP_USER@$REMOTE_SERVER:$REMOTE_INCREMENTAL"

if [ $dryRun -eq 1 ]
then
    echo "DRY RUN"
    rsyncCmd='echo "sudo rsync "'
    cycleCmd='echo "ssh "'
else
    rsyncCmd='sudo rsync '
    cycleCmd='ssh '
fi

rsyncArgs="-e \"ssh -i $LOCAL_SSH_KEY\" -avRz \
    --link-dest $REMOTE_CUR --rsync-path=\"sudo rsync\" \
    $BACKUP_LIST $REMOTE_BACKUP_USER@$REMOTE_SERVER:$REMOTE_NEW"

cycleArgs="$REMOTE_BACKUP_USER@$REMOTE_SERVER -i $LOCAL_SSH_KEY \
    \"/home/$REMOTE_BACKUP_USER/cycleBackups.sh $REMOTE_NEW $REMOTE_CUR\""

eval "$rsyncCmd $rsyncArgs"
eval "$cycleCmd $cycleArgs"

echo "END $NEW_BACKUP"

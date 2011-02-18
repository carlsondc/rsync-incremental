#!/bin/bash

#default label for this backup
LABEL=$(date +%Y-%m-%d-%H%M)
ts=$(date +%s)

DEST=0.0

#defaults
settingsFile=$(dirname $0)/settings
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

. $settingsFile

REMOTE_NEW=$REMOTE_SITE_ROOT/$DEST
nonEmptyVars=(SITE LOCAL_BACKUP_USER REMOTE_BACKUP_USER REMOTE_SERVER REMOTE_BACKUP_DIR REMOTE_BACKUP_DIR_IS_RELATIVE BACKUP_LIST REMOTE_SITE_ROOT REMOTE_CUR EXCLUDE_LIST)

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

echo "START $LABEL $ts"
#echo "sudo rsync -e \"ssh -i $LOCAL_SSH_KEY\" -avRz --link-dest $REMOTE_CUR $BACKUP_LIST $REMOTE_BACKUP_USER@$REMOTE_SERVER:$REMOTE_INCREMENTAL"

if [ $dryRun -eq 1 ]
then
    echo "DRY RUN"
    rsyncCmd='echo "sudo rsync"'
    cycleCmd='echo "ssh"'
    checkLockCmd='echo "ssh"'
    unlockCmd='echo "ssh"'
else
    rsyncCmd='sudo rsync '
    cycleCmd='ssh '
    checkLockCmd='ssh'
    unlockCmd='ssh'
fi

#backup command: copy in symlink targets outside of backup list,
#  hard links to last backup contents, run as sudo at both ends,
#  preserve permissions
rsyncArgs="-e \"ssh -i $LOCAL_SSH_KEY\" -avRz \
    --link-dest $REMOTE_CUR --rsync-path=\"sudo rsync\" \
    --exclude=$EXCLUDE_LIST --copy-unsafe-links \
    $BACKUP_LIST $REMOTE_BACKUP_USER@$REMOTE_SERVER:$REMOTE_NEW"

#rotate command: rotate at depth 1, move 0.0 to 1.0
cycleArgs="$REMOTE_BACKUP_USER@$REMOTE_SERVER -i $LOCAL_SSH_KEY \
    \"sudo /home/$REMOTE_BACKUP_USER/rsync-incremental/server/rotate.sh \
    $REMOTE_SITE_ROOT 1 $DEPTH_ONE_BACKUPS 0\""

#if another 0.0 file exists at destination, don't start backup
checkLockArgs="$REMOTE_BACKUP_USER@$REMOTE_SERVER -i $LOCAL_SSH_KEY \
    \"/home/$REMOTE_BACKUP_USER/rsync-incremental/server/checkLock.sh \
    $REMOTE_NEW \""

alreadyExists=$(eval "$checkLockCmd $checkLockArgs")
if [ $dryRun -eq 0 ]
then
    if [ $alreadyExists -ne 0 ]
    then
        echo "destination already exists: is another backup running?"
        exit 1
    fi
fi

eval "$rsyncCmd $rsyncArgs"
eval "$cycleCmd $cycleArgs"

echo "END $LABEL $ts"

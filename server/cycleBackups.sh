#!/bin/sh
echo "running cycleBackups as $(whoami)"
REMOTE_NEW=$1
REMOTE_CUR=$2
if [ -L $REMOTE_CUR ]
then
    echo "removing $REMOTE_CUR"
    rm $REMOTE_CUR
fi
echo "soft linking $REMOTE_NEW to $REMOTE_CUR"
ln -s $REMOTE_NEW $REMOTE_CUR

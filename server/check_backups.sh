#!/bin/bash
settingsFile=$(dirname $0)/settings
. $settingsFile

nonEmptyVars=(BACKUP_ROOT elapsedSecondsPerUnit warnThresholdUnits warnThresholdSeconds)
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

echo "Checking backups in $BACKUP_ROOT"
echo "Units are $elapsedSecondsPerUnit seconds, warning threshold is $warnThresholdUnits (u) = $warnThresholdSeconds (s)"
for system in $(find $BACKUP_ROOT -maxdepth 1 -mindepth 1 -type d )
do
    numFound=$(find $system -maxdepth 1 -mindepth 1 -name '1.0' -type d | wc -l)
    if [ $numFound -ne 1 ]
    then
        echo "WARNING: No 1.0 directory (last backup) found."
    else
        currentDir=$(find $system -maxdepth 1 -name 1.0 -type d)
        lastBackup=$(date -r $currentDir +%s)
        secondsElapsed=$(expr $(date +%s) - $lastBackup)
        unitsElapsed=$(expr $secondsElapsed / $elapsedSecondsPerUnit)
        if [ $secondsElapsed -gt $warnThresholdSeconds ]
        then
            echo -n "WARNING: "
        fi
        echo "$(basename $system) $unitsElapsed ($secondsElapsed s)"
    fi
done
echo ""
echo "Disk usage"
echo "----------"
df -h
echo ""
echo "Check done."

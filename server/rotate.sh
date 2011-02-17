#!/bin/sh
if [ $# -eq 4 ]
then
    INCREMENTALS_DIR=$1
    TO_DEPTH=$2
    MAX_ALLOWED=$3
    ROTATE_AS_COPY=$4
else
    echo "Usage: $0 incrementalsDir targetDepth maxAtDepth rotateAsCopy"
    exit 1
fi
FROM_DEPTH=$(expr $TO_DEPTH - 1)

#find highest index at destination level
maxIndex=$(find $INCREMENTALS_DIR -maxdepth 1 -mindepth 1 -name "$TO_DEPTH.*" | awk -F '.' '{print $NF}' | sort -g | tail -1)
if [ "$maxIndex" = "" ]
then
    maxIndex=0
fi

#rotate
for i in $(seq $maxIndex -1 0)
do
    src=$INCREMENTALS_DIR/$TO_DEPTH.$i
    dest=$INCREMENTALS_DIR/$TO_DEPTH.$(expr 1 + $i)
    if [ -e $src ]
    then
        echo "rotating $src to $dest"
        mv  $src $dest
    else
        echo "$src doesn't exist, so not rotating"
    fi
done

# move in the new one: copy as link, maintain all
# properties/timestamps/etc
#  OR 
# move
src=$INCREMENTALS_DIR/$FROM_DEPTH.0
dest=$INCREMENTALS_DIR/$TO_DEPTH.0
if [ $ROTATE_AS_COPY -eq 1 ]
then
    echo "Linking $src to $dest"
    cp -al $src $dest
else
    echo "Moving $src to $dest"
    mv $src $dest
fi

#remove any excess
if [ $MAX_ALLOWED -ne -1 ]
then
    MAX_INDEX_ALLOWED=$(expr $MAX_ALLOWED - 1)
    for f in $(find $INCREMENTALS_DIR -maxdepth 1 -mindepth 1 -name "$TO_DEPTH.*")
    do
        i=$(echo $f | awk -F '.' '{print $NF}')
        if [ $i -gt $MAX_INDEX_ALLOWED ]
        then
            echo "Removing $f"
            mv $f $INCREMENTALS_DIR/dead_$(date +%s)_$(basename $f)
        fi
    done
fi


#!/bin/sh
if [ $# -ne 1 ]
then
    echo "usage: $0 dest"
fi
dest=$1
if [ -e $dest ]
then
    echo 1
else
    echo 0
fi

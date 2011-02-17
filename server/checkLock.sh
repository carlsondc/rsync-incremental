#!/bin/sh
if [ $# -ne 1 ]
then
    echo "usage: $0 siteRoot"
fi
siteRoot=$1
if [ -e $siteRoot/0.0 ]
then
    echo 1
else
    echo 0
fi

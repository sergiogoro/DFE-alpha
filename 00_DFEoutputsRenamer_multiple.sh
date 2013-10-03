#!/bin/sh

for file in `ls | grep noname`
do
    name=`perl -n -e '/file (.*) emailed/ && print $1' $file`
    #echo $name
    newname=DFE_multiple_${name}
    mv $file $newname
done

exit 0

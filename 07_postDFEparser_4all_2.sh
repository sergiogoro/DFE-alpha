#!/bin/sh

for file in `ls | grep post | grep -v pl | grep -v processed | grep -v sh`
do
    echo "\nprocessing file ${file} \n"
    perl 06_postDFEparser_3.pl -input ${file}
done

exit 0

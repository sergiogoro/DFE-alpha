#!/bin/sh

for file in `ls | grep multiple | grep -v .pl$ | grep -v processed | grep -v .sh$`
do
    echo "processing file ${file}"
    perl 06_postDFEparser_3.pl -input ${file}
done

exit 0

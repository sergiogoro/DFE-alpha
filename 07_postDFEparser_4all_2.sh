#!/bin/sh

for file in `ls | grep multiple | grep -v .pl$ | grep -v processed | grep -v .sh$`
do
    echo "processing file ${file}"
    #dos2unix ${file}    #Converts newline and other special chars from their dos format to the unix format
    perl 06_postDFEparser_3.pl -input ${file}
done

exit 0

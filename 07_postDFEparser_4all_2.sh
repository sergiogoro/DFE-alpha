#!/bin/sh

indexPath= "/home/sergio/chromatin/analysis/inputs_DFE-alpha/tests/orth/multiple/Index_of_Datasets_and_Windows"

for file in `ls | grep multiple | grep -v .pl$ | grep -v processed | grep -v .sh$`
do
    echo "processing file ${file}"
    #dos2unix ${file}    #Converts newline and other special chars from their dos format to the unix format
    perl 06_postDFEparser_5.pl -input ${file} -index /home/sergio/chromatin/analysis/inputs_DFE-alpha/tests/orth/multiple/Index_of_Datasets_and_Windows
done

exit 0

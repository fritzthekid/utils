#!/bin/bash

if [ $# \< 2 ]; then
    echo "usage ocr.sh input.pdf output [postfix]"
    echo "          postfix: pdf or txt (default)]"
    exit 1
fi

if [ ! -e $1 ]; then
    echo $1 does not exists
    exit 1
fi
if [ ! -d $(dirname $2) ]; then
    echo directory of $2 does not exists
    exit 1
fi

if [ $# \> 2 ]; then
    FORMAT=$3
else
    FORMAT="txt"
fi

if [ $# \> 3 ]; then
    OCRLANG="-l $4"
else
    OCRLANG="-l deu"
fi

TMPDIRNAME=/tmp/ocr-$$
echo ${TMPDIRNAME}
rm -rf ${TMPDIRNAME}
mkdir -p ${TMPDIRNAME}
outfilename=$2


pdftoppm -png $1 ${TMPDIRNAME}/x

for file in ${TMPDIRNAME}/x*.png; do
    tmpoutfile=`echo $file | sed 's/\.png//'`
    echo tmpoutfile: ${tmpoutfile}
    echo tesseract $OCRLANG $file $tmpoutfile $3
    tesseract $OCRLANG $file $tmpoutfile $3
done

if [ "$3" == "pdf" ]; then
    pdfunite ${TMPDIRNAME}/x-*.pdf ${outfilename}.${postfix}
    # pdfsam ${TMPDIRNAME}/x-*.pdf 
else
    cat ${TMPDIRNAME}/x-*.txt > ${outfilename}.${postfix}
fi

rm -rf ${TMPDIRNAME}

exit 0

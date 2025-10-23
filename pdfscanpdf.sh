#!/bin/bash

if [ $# \< 2 ]; then
    echo "usage pdfscanpdf.sh input.pdf output.pdf"
    exit 1
fi

if [ ! -e $1 ]; then
    echo ❌ $1 does not exists
    exit 1
fi

if ! file --mime-type "$1" | grep -q 'application/pdf'; then
    echo "❌ $1 is not type pdf but" `file --mime-type "$1"` 
    exit 1
fi

if [ ! -d $(dirname $2) ]; then
    echo ❌ directory of $2 does not exists
    exit 1
fi

outfilename=$(dirname "$2")/`echo $(basename "$2") | sed 's/\..*//'`

rm -rf /tmp/pdfscanpdf-*
TMPDIRNAME=/tmp/pdfscanpdf-$$
echo ${TMPDIRNAME}
mkdir -p ${TMPDIRNAME}

pdftoppm -png -r 300 $1 ${TMPDIRNAME}/x

for file in ${TMPDIRNAME}/x*.png; do
    tmpoutfile=`echo $file | sed 's/\.png$/.pdf/'`
    echo convert $file $tmpoutfile
    convert $file $tmpoutfile
done

echo pdfunite ${TMPDIRNAME}/x-*.pdf ${outfilename}".pdf"
pdfunite ${TMPDIRNAME}/x-*.pdf ${outfilename}".pdf"

rm -rf ${TMPDIRNAME}

exit 0

#!/bin/bash

if [[ $# -lt 3 ]]; then
    echo "error: 3 arguments expected, $# where given"
    echo "usage pdfmkduplex.sh <left.pdf> <right.pdf> <destination>"
    exit -1
fi

if [ ! -e $1 ]; then
    echo $1 does not exists
    exit 1
fi
if [ ! -e $2 ]; then
    echo $2 does not exists
    exit 1
fi
if [ ! -d $(dirname $3) ]; then
    echo directory of $3 does not exists
    exit 1
fi

rm -rf /tmp/mkduplex-*
TMPDIRNAME=/tmp/mkduplex-$$
mkdir -p ${TMPDIRNAME}
outfilename=$2

count=1

pdfseparate -f $count -l $count $1 ${TMPDIRNAME}/${count}_l.pdf
RETCODE=$?
while [[ $RETCODE -eq 0 ]]
do
    pdfseparate -f $count -l $count $2 ${TMPDIRNAME}/${count}_r.pdf
    if [[ $? -ne 0 ]]
    then
	echo "$2 has less page than $1 ?"
	echo "continue with one more left page, but missing last $1 pages"
	break
    fi
    count=$[$(echo $count) + 1]
    pdfseparate -f $count -l $count $1 ${TMPDIRNAME}/${count}_l.pdf 2> ${TMPDIRNAME}/return.txt
    RETCODE=$?
    if [[ $RETCODE -ne 99 ]]; then
	cat ${TMPDIRNAME}/return.txt
    fi
    rm -f ${TMPDIRNAME}/return.txt
done

pdfunite ${TMPDIRNAME}/* $3
# rm -rf ${TMPDIRNAME}

echo -n "Number of pages $3: " 
pdfinfo $3 | awk '/^Pages:/ {print $2}'

exit 0

#!/bin/bash

while getopts ":l:r:d:h" opt; do
  case ${opt} in
    l )
      left_pdf=$OPTARG
      ;;
    r )
      right_pdf=$OPTARG
      ;;
    d )
      destination=$OPTARG
      ;;
    h )
      echo "usage: pdfmkduplex.sh -l <left.pdf> -r <right.pdf> -d <destination>"
      exit 0
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [[ -z "$left_pdf" || -z "$right_pdf" || -z "$destination" ]]; then
  echo "usage: pdfmkduplex.sh -l <left.pdf> -r <right.pdf> -d <destination>"
  exit 1
fi

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

lenl=`pdfinfo $1 2> /dev/null | awk '/^Pages:/ {print $2}'`
lenr=`pdfinfo $2 2> /dev/null | awk '/^Pages:/ {print $2}'`
if [[ ${lenl} -ne ${lenr} ]]; then
    echo "error: length of documents left ($lenl) and of right ($lenr) not equal"
    exit 1
fi

rm -rf /tmp/mkduplex-*
TMPDIRNAME=/tmp/mkduplex-$$
mkdir -p ${TMPDIRNAME}
outfilename=$2

count=1
count0=$(printf %03d $count)
pdfseparate -f $count -l $count $1 ${TMPDIRNAME}/${count0}_l.pdf
RETCODE=$?
while [[ $RETCODE -eq 0 ]]
do
    countinv=$[ $lenr + 1 - $count ]
    pdfseparate -f $countinv -l $countinv $2 ${TMPDIRNAME}/${count0}_r.pdf
    if [[ $? -ne 0 ]]
    then
	echo "$2 has less page than $1 ?"
	echo "continue with one more left page, but missing last $1 pages"
	break
    fi
    count=$[$(echo $count) + 1]
    count0=$(printf %03d $count)
    pdfseparate -f $count -l $count $1 ${TMPDIRNAME}/${count0}_l.pdf 2> ${TMPDIRNAME}/return.txt
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

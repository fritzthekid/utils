#!/bin/bash

usage() {
    echo "Usage: pdfmkduplex.sh -l <left.pdf> -r <right.pdf> -o <destination>"
    exit 1
}

while getopts ":l:r:o:h" opt; do
    case ${opt} in
        l )
            left_pdf=$OPTARG
            ;;
        r )
            right_pdf=$OPTARG
            ;;
        o )
            destination=$OPTARG
            ;;
        h )
            usage
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

if [[ -z "$left_pdf" || -z "$right_pdf" || -z "$destination" ]]; then
    usage
fi

if [ ! -e "$left_pdf" ]; then
    echo "$left_pdf does not exist"
    exit 1
fi

if [ ! -e "$right_pdf" ]; then
    echo "$right_pdf does not exist"
    exit 1
fi

if [ ! -d "$(dirname "$destination")" ]; then
    echo "Directory of $destination does not exist"
    exit 1
fi

lenl=$(pdfinfo "$left_pdf" 2> /dev/null | awk '/^Pages:/ {print $2}')
lenr=$(pdfinfo "$right_pdf" 2> /dev/null | awk '/^Pages:/ {print $2}')
if [[ ${lenl} -ne ${lenr} ]]; then
    echo "Error: length of documents left ($lenl) and right ($lenr) are not equal"
    exit 1
fi

rm -rf /tmp/mkduplex-*
TMPDIRNAME=/tmp/mkduplex-$$
mkdir -p "${TMPDIRNAME}"
outfilename=$right_pdf

count=1
count0=$(printf %03d $count)
pdfseparate -f $count -l $count "$left_pdf" "${TMPDIRNAME}/${count0}_l.pdf"
RETCODE=$?

while [[ $RETCODE -eq 0 ]]; do
    countinv=$(( lenr + 1 - count ))
    pdfseparate -f $countinv -l $countinv "$right_pdf" "${TMPDIRNAME}/${count0}_r.pdf"
    if [[ $? -ne 0 ]]; then
        echo "$right_pdf has fewer pages than $left_pdf?"
        echo "Continuing with one more left page, but missing last $left_pdf pages"
        break
    fi
    count=$((count + 1))
    count0=$(printf %03d $count)
    pdfseparate -f $count -l $count "$left_pdf" "${TMPDIRNAME}/${count0}_l.pdf" 2> "${TMPDIRNAME}/return.txt"
    RETCODE=$?
    if [[ $RETCODE -ne 99 ]]; then
        cat "${TMPDIRNAME}/return.txt"
    fi
    rm -f "${TMPDIRNAME}/return.txt"
done

pdfunite "${TMPDIRNAME}"/* "$destination"
# rm -rf ${TMPDIRNAME}

echo -n "Number of pages $destination: "
pdfinfo "$destination" | awk '/^Pages:/ {print $2}'

exit 0

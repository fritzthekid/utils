#!/bin/bash

usage() {
    echo "Usage: ocr.sh -i <input.pdf> -o <output> [-f <pdf|txt>] [-l <language>]"
    echo "  -i <input.pdf>   : Input PDF file"
    echo "  -o <output>      : Output file"
    echo "  -f <format>      : Output format (pdf or txt, default: txt)"
    echo "  -l <language>    : OCR language (default: deu)"
    exit 1
}

FORMAT="txt"
OCRLANG="-l deu"

while getopts ":i:o:f:l:h" opt; do
    case ${opt} in
        i )
            input_pdf=$OPTARG
            ;;
        o )
            output=$OPTARG
            ;;
        f )
            FORMAT=$OPTARG
            ;;
        l )
            OCRLANG="-l $OPTARG"
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

if [[ -z "$input_pdf" || -z "$output" ]]; then
    usage
fi

if [ ! -e "$input_pdf" ]; then
    echo "$input_pdf does not exist"
    exit 1
fi

if [ ! -d "$(dirname "$output")" ]; then
    echo "Directory of $output does not exist"
    exit 1
fi

TMPDIRNAME=$(mktemp -d /tmp/ocr-XXXXXX)
echo "$TMPDIRNAME"

pdftoppm -png "$input_pdf" "${TMPDIRNAME}/x"

for file in "${TMPDIRNAME}/x"*.png; do
    tmpoutfile="${file%.png}"
    echo "Processing $file"
    tesseract $OCRLANG "$file" "$tmpoutfile" "$FORMAT"
done

if [ "$FORMAT" == "pdf" ]; then
    pdfunite "${TMPDIRNAME}/x-"*.pdf "${output}.${FORMAT}"
else
    cat "${TMPDIRNAME}/x-"*.txt > "${output}.${FORMAT}"
fi

rm -rf "$TMPDIRNAME"

exit 0

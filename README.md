# Basic Helpers to support everydays on linux

## ocr (optical character recognition) of a large pdf

Reason behind the tool, I could not find a proper tool to do a simple ocr on a larger pdf to "text" or to "searchable pdf" 

~~~
$ ocr.sh
usage ocr.sh input.pdf output [postfix]
          postfix: pdf or txt (default)]
$ # or
$ ocr.sh input.pdf output txt | pdf [eng] # last argument any language, default language german: deu
~~~
The too does not support options only arguments

## Split and Join two single sided scanns to one double sided scan

Reason behind the tool, I do have only a simple scanner, not supporting double sided prints
The tool splits the left side scanns and the right side scanns into single sheets.
This sheets are united to one the output in the proper order.

~~~
# pdfmkduplex.sh
error: 3 arguments expected, 0 where given
usage pdfmkduplex.sh <left.pdf> <right.pdf> <destination>
~~~
The tool does not support proper help or any options.

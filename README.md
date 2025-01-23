# Basic Helpers to support everydays on linux

## ocr (optical character recognition) of a large pdf

Reason behind the tool: I could not find a proper tool to do a simple OCR on a larger PDF to "text" or to "searchable PDF".

~~~
$ ocr.sh
Usage: ocr.sh -i <input.pdf> -o <output> [-f <pdf|txt>] [-l <language>]
  -i <input.pdf>   : Input PDF file
  -o <output>      : Output file
  -f <format>      : Output format (pdf or txt, default: txt)
  -l <language>    : OCR language (default: deu)
~~~



## Split and Join two single sided scans to one double sided scan

Reason behind the tool, I do have only a simple scanner, not supporting double
sided prints.
The tool splits the left side scans and the right side scans into single sheets.
These sheets are united to output in the proper order.

One additional issue has been taken care of, you do not have to restack the
right pages before scanning, you can scan the entire right pages in reverse
order, therefore you keep the whole in pack in order. Than with script can
take care about the order optionally.
~~~
# pdfmkduplex.sh
usage: pdfmkduplex.sh -l <left.pdf> -r <right.pdf> -o <destination> [-R]
  -l <left.pdf>      : Left PDF file
  -r <right.pdf>     : Right PDF file
  -o <destination>   : Output PDF file
  -R                 : Reverse page order of the right PDF file
~~~


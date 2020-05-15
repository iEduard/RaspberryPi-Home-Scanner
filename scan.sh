#!/bin/bash

OUT_DIR=/media/ScannerShare
TMP_DIR=`mktemp -d`
FILE_NAME=scan_`date +%Y-%m-%d-%H%M%S`
LANGUAGE="deu"                 # the tesseract language - ensure you installed it eng = englisch deu = german

echo 'scanning...'
scanimage --resolution 300 \
          --batch="$TMP_DIR/scan_%03d.pnm" \
          --format=pnm \
          --mode Gray \
          --source 'ADF Front'
echo "Output saved in $TMP_DIR/scan*.pnm"

cd $TMP_DIR

for i in scan_*.pnm; do
    echo "${i}"
    convert "${i}" "${i}.tif"
done

# do OCR
echo 'doing OCR...'
for i in scan_*.tif; do
    echo "${i}"
    tesseract "$i" "$i" -l $LANGUAGE hocr
    hocr2pdf -i "$i" -s -o "$i.pdf" < "$i.hocr"
done

# create PDF
echo 'creating PDF...'
pdftk *.tif.pdf cat output "compiled.pdf"

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$FILE_NAME.pdf" compiled.pdf

cp $FILE_NAME.pdf $OUT_DIR/

rm -rf $TMP_DIR
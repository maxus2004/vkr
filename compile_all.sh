echo обрезаем титулы ...
magick -density 300 тз/титул_тз.pdf -crop 2008x3030+295+240 тз/титул_тз.jpg
magick -density 300 Задание-календарный\ план.pdf -crop 2008x3030+295+240 Задание-календарный\ план_%d.jpg

echo конвертируем листы в картинки ...
magick -density 100 'Функциональная схема ПО.pdf' -background white -alpha remove -rotate 90 scheme1.png
magick -density 100 'Функциональная схема автомобиля.pdf' -background white -alpha remove -rotate 90 scheme2.png
magick -density 100 'Принципиальная схема.pdf' -background white -alpha remove -rotate 90 scheme3.png
magick -density 100 'Фотографии макета.pdf' -background white -alpha remove -rotate 90 scheme4.png

echo компилируем rpz.typ в pdf ...
typst compile rpz.typ

echo сжимаем pdf ...
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=rpz_compressed.pdf rpz.pdf

echo фиксим pdf для TestVkr.exe ...
pdftocairo -pdf rpz_compressed.pdf rpz_compressed_cairo.pdf && qpdf --linearize rpz_compressed_cairo.pdf rpz_compressed_cairo_fixed.pdf
cp rpz_compressed_cairo_fixed.pdf ВКРБ_РПЗ_ДорошинМЕ.pdf

echo отправляем на комп с виндой ...
scp ВКРБ_РПЗ_ДорошинМЕ.pdf servermaksa.ru:/mnt/nas/public/ВКРБ_РПЗ_ДорошинМЕ.pdf
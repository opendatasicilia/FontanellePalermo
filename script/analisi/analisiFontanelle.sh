#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/../../dati/analisi
mkdir -p "$folder"/rawdata

URL="https://www.amapspa.it/it/analisi-fontanelle-di-palermo/"

# leggi la risposta HTTP del sito
code=$(curl -s -L -o /dev/null -w '%{http_code}' "$URL")

# se il sito è raggiungibile scarica i dati
if [ $code -eq 200 ]; then
  # scarica lista pagine
  curl -kL "$URL" | scrape -be '//aside//li/a' | xq '.html.body.a[]' | mlr --j2c label URL,label then put -S '$id=sub($label," - .+","");$nome=sub($label,"^FW[0-9]+ - .+lla ","")' then clean-whitespace then sort -f id >"$folder"/rawdata/lista

  mlr --c2j cat "$folder"/rawdata/lista | while read line; do
    URLF=$(echo "$line" | jq -r '.URL')
    id=$(echo "$line" | jq -r '.id')
    curl -kL "$URLF" | vd -f html +:table_0:: -b -o "$folder"/rawdata/"$id".csv
    mlr -I --csv filter -x  '${Unità di misura}=~"ERR"' then put -S '$id="'"$id"'"' then label parametro,unitaDiMisura,limiteMassimo then put -S '$data=$[[4]];$data=regextract_or_else($data,"[0-9]+/[0-9]+/[0-9]+","")' then rename -r '.+analisi.+',valore then put -S '$valore=gsub($valore,"\.","");$valore=sub($valore,",",".");$limiteMassimo=gsub($limiteMassimo,"\.","");$limiteMassimo=sub($limiteMassimo,",",".")' then put -S '$dateISO = strftime(strptime($data, "%d/%m/%Y"),"%Y-%m-%d")' "$folder"/rawdata/"$id".csv
  done
  mlr --csv cat "$folder"/rawdata/*.csv >"$folder"/../../dati/analisi/tmp.csv
  nome=$(mlr --c2n head -n 1 then cut -f dateISO  "$folder"/../../dati/analisi/tmp.csv | tr -d '\r')
  mv "$folder"/../../dati/analisi/tmp.csv "$folder"/../../dati/analisi/"$nome".csv
  mlr -I --csv filter -x -S '$dateISO==""' then uniq -a "$folder"/../../dati/analisi/"$nome".csv
fi

#then

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
  curl -kL "$URL" >"$folder"/rawdata/html
  scrape <"$folder"/rawdata/html -be '//aside//li/a' | xq '.html.body.a[]' | mlr --j2c label URL,label then put -S '$id=sub($label," - .+","");$nome=sub($label,"^FW[0-9]+ - .+lla ","")' then clean-whitespace then sort -f id >"$folder"/rawdata/lista

  # per ogni fontanella estrai i dati dalla pagina di dettaglio
  mlr --c2j cat "$folder"/rawdata/lista | while read line; do
    # estrai URL pagina
    URLF=$(echo "$line" | jq -r '.URL')
    # estrai ID fontanelle
    id=$(echo "$line" | jq -r '.id')
    # scarica dati fontanelle
    curl -kL "$URLF" | vd -f html +:table_0:: -b -o "$folder"/rawdata/"$id".csv
    # ristruttura e pulisci file di output
    mlr -I --csv filter -x '${Unità di misura}=~"ERR"' then put -S '$id="'"$id"'"' then label parametro,unitaDiMisura,limiteMassimo then put -S '$data=$[[4]];$data=regextract_or_else($data,"[0-9]+/[0-9]+/[0-9]+","")' then rename -r '.+analisi.+',valore then put -S '$valore=gsub($valore,"\.","");$valore=sub($valore,",",".");$limiteMassimo=gsub($limiteMassimo,"\.","");$limiteMassimo=sub($limiteMassimo,",",".")' then put -S '$dateISO = strftime(strptime($data, "%d/%m/%Y"),"%Y-%m-%d")' "$folder"/rawdata/"$id".csv
  done
  # unisci i file singoli in uno solo
  mlr --csv cat "$folder"/rawdata/*.csv >"$folder"/../../dati/analisi/tmp.csv
  # estrai data più recente dal file e usa questa data per dare il nome al file
  nome=$(mlr --c2n stats1 -a max -f dateISO "$folder"/../../dati/analisi/tmp.csv | tr -d '\r')
  mv "$folder"/../../dati/analisi/tmp.csv "$folder"/../../dati/analisi/"$nome".csv
  mlr -I --csv filter -x -S '$dateISO==""' then uniq -a then sort -f dateISO,id,parametro "$folder"/../../dati/analisi/"$nome".csv
  dos2unix "$folder"/../../dati/analisi/"$nome".csv
fi

# scarica kml fontanelle
curl -kL "https://www.google.com/maps/d/u/0/kml?mid=17JvcNAruYApLI5TIaNFStgAwEfiUanEE&forcekml=1" >"$folder"/../../dati/analisi/fontanelle.kml
# converti kml in CSV
ogr2ogr  -f CSV /vsistdout/ "$folder"/../../dati/analisi/fontanelle.kml -lco GEOMETRY=AS_XYZ  >"$folder"/../../dati/analisi/fontanelle.csv
# rinomina campo
mlr -I --csv rename Codice_Fontana,id then reorder -f id "$folder"/../../dati/analisi/fontanelle.csv
# converti in formato unix
dos2unix "$folder"/../../dati/analisi/fontanelle.csv

#!/bin/bash

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# leggi parametri vari
source "$folder"/config

# crea cartella output dati
mkdir -p "$folder"/output

# https://isoline.route.api.here.com/routing/7.2/calculateisoline.json?app_id=6fXktj6OT4AnDS5D4Ysv&app_code=CTQRhQbcNqfdWkybbb6lMA&mode=fastest;pedestrian;traffic:disabled&rangetype=time&start=geo!52.51578,13.37749&range=300

# crea ID fontanelle, salva in TSV e rimuovi intestazione
mlr --headerless-csv-output --c2t cat -n then cut -f n,X,Y "$folder"/../../risorse/da_PEC_AMAP/Mappa-Fontanelle-di-Palermo.csv >"$folder"/source.tsv

# # # isolinee a piedi, percorso più rapido, in 5 minuti # # #

# modalità: tempo a piedi
modalita="tp"
# tempo in secondi per isolinee da 5 minuti, quindi 300 secondi
tempo="300"

<<commento
while IFS=$'\t' read -r n long lat; do
    #echo "$r $long $lat"
    curl "https://isoline.route.api.here.com/routing/7.2/calculateisoline.json?app_id=$app_id&app_code=$app_code&mode=fastest;pedestrian;traffic:disabled&rangetype=time&start=geo!$lat,$long&range=$tempo" | jq . >"$folder"/output/"$modalita"_"$n".json
done <"$folder"/source.tsv

echo "ID,WKT" >"$folder"/"$modalita".csv

for i in "$folder"/output/*.json; do
  printf ''"$i"',"POLYGON ((' >>"$folder"/"$modalita".csv
  jq <"$i" -r '.response.isoline[0].component[0].shape[]' | mlr --nidx --ifs "," reorder -f 2,1 | tr '\n' ',' >>"$folder"/"$modalita".csv
  printf "\n" >>"$folder"/"$modalita".csv
done

sed -i -r 's/,$/\)\)"/g;s|'"$folder"'/output/||g;s/\.json//g' "$folder"/"$modalita".csv
commento

for i in "$folder"/output/*.json; do
  #crea una variabile per estrarre nome e estensione
  filename=$(basename "$i")
  #estrai estensione
  extension="${filename##*.}"
  #estrai nome file
  filename="${filename%.*}"
  echo "ID,WKT" >"$folder"/output/"$filename".csv
  printf ''"$filename"',"POLYGON ((' >>"$folder"/output/"$filename".csv
  jq <"$i" -r '.response.isoline[0].component[0].shape[]' | mlr --nidx --ifs "," reorder -f 2,1 | tr '\n' ',' >>"$folder"/output/"$filename".csv
  printf "\n" >>"$folder"/output/"$filename".csv
  sed -i -r 's/,$/\)\)"/g' "$folder"/output/"$filename".csv
  ogr2ogr -f geojson "$folder"/output/"$filename".geojson "$folder"/output/"$filename".csv
done

mapshaper -i "$folder"/output/*.geojson combine-files -merge-layers -o "$folder"/output/"$modalita".shp

ogr2ogr "$folder"/"$modalita".shp "$folder"/output/"$modalita".shp -dialect sqlite -sql "SELECT ST_Union(geometry) AS geometry FROM $modalita"

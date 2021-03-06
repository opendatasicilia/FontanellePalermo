#!/bin/bash

### requisiti ###
# GDAL/OGR https://gdal.org/
# Miller https://github.com/johnkerl/miller
# mapshaper https://github.com/mbloch/mapshaper
### requisiti ###

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# leggi parametri vari
source "$folder"/config

# crea cartelle per output dati
mkdir -p "$folder"/output
mkdir -p "$folder"/rawdata


# crea ID fontanelle, salva in TSV e rimuovi intestazione
mlr --headerless-csv-output --c2t cat -n \
  then cut -f n,X,Y \
  then put '$n = fmtnum($n, "%03d")' "$folder"/../../risorse/da_PEC_AMAP/Mappa-Fontanelle-di-Palermo.csv >"$folder"/source.tsv

# # # isolinee in Automobile, percorso più rapido, in 5 e 10 minuti # # #

# modalità: Tempo in Automobile, quindi "ta"
modalita="ta"
# tempo in secondi per isolinee da 5 e 10 minuti, quindi 300 e 600 secondi
tempo="300,600"

# svuota cartelle dati
rm "$folder"/output/"$modalita"*
rm "$folder"/rawdata/"$modalita"*

# per ogni fontanella in lista calcola le isocrone secondo la variabile tempo
while IFS=$'\t' read -r n long lat; do
  #echo "$r $long $lat"
  curl "https://isoline.route.api.here.com/routing/7.2/calculateisoline.json?app_id=$app_id&app_code=$app_code&mode=fastest;car;traffic:disabled&rangetype=time&destination=geo!$lat,$long&range=$tempo" | jq . >"$folder"/rawdata/"$modalita"_"$n".json
done <"$folder"/source.tsv


# crea l'array dei valori di isocrona, ovvero quelli listati nella variabile tempo
lista=($(sed 's|,| |g' <<<$tempo))

# per ogni file generato dalle API, crea un CSV geografico e un geojson
for i in "$folder"/rawdata/"$modalita"*.json; do
  #crea una variabile per estrarre nome e estensione
  filename=$(basename "$i")
  #estrai estensione
  extension="${filename##*.}"
  #estrai nome file
  filename="${filename%.*}"
  # per ogni valore di isocrona e per ogni fontana crea un CSV geografico e un geojson
  for l in ${lista[@]}; do
    echo "ID,range,WKT" >"$folder"/output/"$filename"_"$l".csv
    printf ''"$filename"','"$l"',"POLYGON ((' >>"$folder"/output/"$filename"_"$l".csv
    jq <"$i" -r '.response.isoline[] | select(.range=='"$l"') |.component[0].shape[]' | mlr --nidx --ifs "," reorder -f 2,1 | tr '\n' ',' >>"$folder"/output/"$filename"_"$l".csv
    printf "\n" >>"$folder"/output/"$filename"_"$l".csv
    sed -i -r 's/,$/\)\)"/g' "$folder"/output/"$filename"_"$l".csv
    ogr2ogr -f geojson "$folder"/output/"$filename"_"$l".geojson "$folder"/output/"$filename"_"$l".csv
  done
done

# per ogni valore di isocrona fai l'unione di tutti i geojson e fai il merge
for l in ${lista[@]}; do
  mapshaper -i "$folder"/output/"$modalita"*"$l".geojson combine-files -merge-layers -o "$folder"/output/"$modalita"_"$l".shp
  ogr2ogr -f geojson "$folder"/"$modalita"_"$l".geojson "$folder"/output/"$modalita"_"$l".shp -dialect sqlite -sql 'SELECT ST_Union(geometry) AS geometry FROM '"$modalita"'_'"$l"''
done


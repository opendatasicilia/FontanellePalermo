#!/bin/bash

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# leggi token di Mapbox (notare bene, questo file non è sottoposto a versionamento, per non diffondere il token)
source "$folder"/api

mkdir -p "$folder"/staticImgs
mkdir -p "$folder"/staticImgs/256
mkdir -p "$folder"/staticImgs/512

# genera immagini statiche 512x512 px
while IFS=$'\t' read -r id via lat lon; do
    wget -O "$folder"/staticImgs/512/"$id".png "https://api.mapbox.com/styles/v1/mapbox/streets-v10/static/pin-s-1+9ed4bd($lon,$lat)/$lon,$lat,14,0,0/512x512?access_token=$apiMapbox"
done <"$folder"/fontanelle.tsv

# genera immagini statiche 256x256 px
while IFS=$'\t' read -r id via lat lon; do
    wget -O "$folder"/staticImgs/256/"$id".png "https://api.mapbox.com/styles/v1/mapbox/streets-v10/static/pin-s+75CFF0($lon,$lat)/$lon,$lat,13,0,0/256x256?access_token=$apiMapbox"
done <"$folder"/fontanelle.tsv

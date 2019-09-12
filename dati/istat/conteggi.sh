#!/bin/bash

# aggregazione e conteggi fatti in linea con le categorie di questo articolo https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5133062/

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mlr --csv put 'if ($Eta >= 18 && $Eta <66) {$classe = "prima"} elif ($Eta >= 65 && $Eta <76) {$classe = "seconda"} else {$classe = "altro"}' \
then cut -f "Eta,Totale Maschi,Totale Femmine,classe" PalermoISTATPopolazioneGennaio2019.csv >"$folder"/tmp.csv

mlr --csv stats1 -a sum -g classe -f "Totale Maschi,Totale Femmine" "$folder"/tmp.csv >"$folder"/PalermoISTATPopolazioneGennaio2019Gruppi.csv

## Appunti descrittivi

**NOTA BENE**: al momento sono appunti incomprensibili

Per contare quante fontane e quali sono raggiungibili da un'area:

- dal layer dei poligoni delle isocrone genera un layer con linee

```
mapshaper poly.shp -lines -o lines.shp
```

- da queste linee genera i poligoni (sono i poligoni di intersezione tra tutti i poligoni)

```
mapshaper lines.shp -polygons -o polytemp.shp
```

- da questi poligoni i centroidi inner

```
mapshaper polytemp.shp -points inner -o points.shp
```

- cancella da questi punti quelli che non toccano il layer dei poligoni delle isocrone

```
mapshaper points.shp -clip poly.shp -o points_temp.shp
```

- fai il join spaziale tra poligoni delle isocrone e questi punti

```
mapshaper points_temp.shp -join poly.shp calc='numero = count(),elenco = collect(value).toString()' -o joinpoints.geojson
```

In output si avrà qualcosa come

```json
"properties": {
        "numero": 2,
        "elenco": "A,C"
      }
```

- fai il join spaziale tra questi punti e poligoni di intersezione tra tutti i poligoni


## Script testato e funzionante

```
mapshaper input.geojson -lines -o tmp_lines.geojson
mapshaper tmp_lines.geojson -polygons -o tmp_polygons.shp
mapshaper tmp_polygons.shp -points inner -o tmp_points.shp
mapshaper tmp_points.shp -clip input.geojson -o tmp_points_temp.shp
mapshaper tmp_points_temp.shp -join input.geojson calc='numero = count(),elenco = collect(value).toString()' -o tmp_joinpoints.geojson
mapshaper tmp_polygons.shp -join tmp_joinpoints.geojson -o output.geojson
rm ./tmp_*
```

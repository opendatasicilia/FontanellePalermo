## Dati esistenti

La query di overpass è https://overpass-turbo.eu/s/MSy

```
[out:json][timeout:25];
{{geocodeArea:Palermo}}->.searchArea;
(
  node["amenity"="drinking_water"](area.searchArea);
);
out body;
>;
out skel qt;
```

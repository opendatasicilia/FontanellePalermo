## Appunti descrittivi

**NOTA BENE**: al momento sono appunti incomprensibili

- dissolvo tutti i perimetri dei poligoni sovrapposti

```sql
SELECT DropGeoTable('tmp_union_boundary');
CREATE TABLE "tmp_union_boundary" AS
SELECT  "range",st_union(st_boundary (geom)) as geom
FROM "tp_300";
SELECT RecoverGeometryColumn('tmp_union_boundary', 'geom', 4326, 'MULTILINESTRING', 'XY');
```

- esplodo la tabella di sopra

```sql
SELECT ElementaryGeometries('tmp_union_boundary','geom','tmp_union_boundary_elem','pk_elem','multi_id', 1 ) AS num, 'perimetri esplosi' as label;
```

-- utilizzo la funzione `ST_Polygonalize` per creare un poligono per ogni area delimitata dai perimetri

```sql
SELECT DropGeoTable('tmp_Aree');
CREATE TABLE "tmp_Aree" AS
SELECT st_polygonize("geom") AS geom
FROM "tmp_union_boundary_elem";
SELECT RecoverGeometryColumn('tmp_Aree', 'geom', 4326, 'MULTIPOLYGON', 'XY');
```

-- esplodo la tabella di sopra

```sql
SELECT ElementaryGeometries('tmp_Aree','geom','tmp_Aree_elem','pk_elem','multi_id', 1 ) AS num, 'Aree esplose' AS label;
```

-- PULISCO elimino micro aree 

```sql
SELECT DropGeoTable('tmp_Aree_elem_pulito');
CREATE TABLE "tmp_Aree_elem_pulito" AS
SELECT pk_elem, multi_id, geom
FROM "tmp_Aree_elem"
WHERE ST_Area (ST_Transform(geom,3004)) > 1.0;
SELECT RecoverGeometryColumn('tmp_Aree_elem_pulito', 'geom', 4326, 'POLYGON', 'XY');
```

-- creo i centroidi inner dai poligoni appena creati

```sql
SELECT DropGeoTable('centroid_Inner');
CREATE TABLE "centroid_Inner" AS
SELECT pk_elem, st_PointOnSurface (geom) AS geom
FROM tmp_Aree_elem_pulito;
SELECT RecoverGeometryColumn('centroid_Inner', 'geom', 4326, 'POINT', 'XY');
```

-- aggiungo attributi alle aree esplose tramite join spaziale

```sql
SELECT DropGeoTable('areeComputo');
CREATE TABLE "areeComputo" AS
SELECT p.pk_elem AS pk, t1.nro AS nro, t1.ids AS ids, p.geom
FROM "tmp_Aree_elem_pulito" p 
JOIN
    (SELECT c.pk_elem AS pk_elem, p.id, count(*) AS nro, group_concat(id) AS ids 
    FROM centroid_inner c, tp_300 p
    WHERE st_contains (p.geom,c.geom)
    GROUP BY 1
    ORDER BY 3 desc) t1
ON (p.pk_elem = t1.pk_elem);
SELECT RecoverGeometryColumn('areeComputo', 'geom', 4326, 'POLYGON', 'XY');
```

-- elimino le tabelle inutili

```sql
DROP TABLE "tmp_union_boundary";
DROP TABLE "tmp_union_boundary_elem";
DROP TABLE "tmp_Aree";
DROP TABLE "tmp_Aree_elem";
DROP TABLE "tmp_Aree_elem_pulito";
DROP TABLE "centroid_Inner";
```

-- ottimizzo database

```sql
UPDATE geometry_columns_statistics set last_verified = 0;
SELECT UpdateLayerStatistics('geometry_table_name');
VACUUM;
```

Testato sul file `tp_300.geojson` funziona!

Script SQL presente nella cartella.

**Output**

rowid|pk|nro|ids|geo
--|---|---|---|---
351|398|8|tp_062,tp_072,tp_077,tp_078,tp_079,tp_080,tp_081,tp_094|BLOB sz=228 GEOMETRY
114|140|7|tp_035,tp_040,tp_041,tp_052,tp_053,tp_139,tp_144|BLOB sz=196 GEOMETRY
128|154|7|tp_035,tp_040,tp_041,tp_043,tp_052,tp_053,tp_144|BLOB sz=164 GEOMETRY
156|183|7|tp_002,tp_035,tp_040,tp_041,tp_043,tp_052,tp_053|BLOB sz=116 GEOMETRY
165|193|7|tp_002,tp_035,tp_040,tp_043,tp_052,tp_053,tp_129|BLOB sz=260 GEOMETRY
352|399|7|tp_062,tp_072,tp_077,tp_078,tp_079,tp_081,tp_094|BLOB sz=340 GEOMETRY
355|408|7|tp_062,tp_072,tp_077,tp_078,tp_080,tp_081,tp_094|BLOB sz=196 GEOMETRY
110|134|6|tp_035,tp_040,tp_041,tp_043,tp_052,tp_053|BLOB sz=276 GEOMETRY
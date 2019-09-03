-- ScriptSQL da lanciare in SpatiaLite_gui >=4.3a

-- Creo tabella e aggiungo dati

SELECT DropGeoTable('tp_300_link');
CREATE TABLE "tp_300_link" AS
SELECT t."pk", t."id", t."range", f."Nome",f."Indirizzo",f."Coordinate",f.maps,f.osm,t."geom"
FROM "tp_300" t, "Fontanelle_link" f
WHERE t.id = f.id;
SELECT RecoverGeometryColumn('tp_300_link', 'geom', 4326, 'MULTIPOLYGON', 'XY');

-- dissolvo tutti i perimetri dei poligoni sovrapposti

SELECT DropGeoTable('tmp_union_boundary');
CREATE TABLE "tmp_union_boundary" AS
SELECT  "range",st_union(st_boundary (geom)) as geom
FROM "tp_300_link";
SELECT RecoverGeometryColumn('tmp_union_boundary', 'geom', 4326, 'MULTILINESTRING', 'XY');

SELECT ElementaryGeometries('tmp_union_boundary','geom','tmp_union_boundary_elem','pk_elem','multi_id', 1 ) AS num, 'perimetri esplosi' as label;

-- utilizzo la funzione `ST_Polygonalize` per creare un poligono per ogni area delimitata dai perimetri

SELECT DropGeoTable('tmp_Aree');
CREATE TABLE "tmp_Aree" AS
SELECT st_polygonize("geom") AS geom
FROM "tmp_union_boundary_elem";
SELECT RecoverGeometryColumn('tmp_Aree', 'geom', 4326, 'MULTIPOLYGON', 'XY');

SELECT ElementaryGeometries('tmp_Aree','geom','tmp_Aree_elem','pk_elem','multi_id', 1 ) AS num, 'Aree esplose' AS label;

-- PULISCO elimino micro aree 

SELECT DropGeoTable('tmp_Aree_elem_pulito');
CREATE TABLE "tmp_Aree_elem_pulito" AS
SELECT pk_elem, multi_id, geom
FROM "tmp_Aree_elem"
WHERE ST_Area (ST_Transform(geom,3004)) > 1.0;
SELECT RecoverGeometryColumn('tmp_Aree_elem_pulito', 'geom', 4326, 'POLYGON', 'XY');

-- creo i centroidi inner dai poligoni appena creati

SELECT DropGeoTable('centroid_Inner');
CREATE TABLE "centroid_Inner" AS
SELECT pk_elem, st_PointOnSurface (geom) AS geom
FROM tmp_Aree_elem_pulito;
SELECT RecoverGeometryColumn('centroid_Inner', 'geom', 4326, 'POINT', 'XY');

-- aggiungo attributi alle aree esplose tramite join spaziale

SELECT DropGeoTable('areeComputo');
CREATE TABLE "areeComputo" AS
SELECT p.pk_elem AS pk, t1.nro AS nro, t1.ids AS ids,
						t1."Nome_i",
						t1."Indirizzo_i",
						t1."Coordinate_s",
						t1."maps_s",
						t1."osm_s", 
						p.geom
FROM "tmp_Aree_elem_pulito" p 
JOIN
    (SELECT c.pk_elem AS pk_elem, 
			group_concat(p."Nome", " | ") AS "Nome_i",
			group_concat(p."Indirizzo", " | ") AS "Indirizzo_i",
			group_concat(p."Coordinate", " | ") AS "Coordinate_s",
			group_concat(p.maps, " | ") AS "maps_s",
			group_concat(p.osm, " | ") AS "osm_s", 
			count(*) AS nro, 
			group_concat(REPLACE(id,'tp_','')) AS ids 
    FROM centroid_inner c, tp_300_link p
    WHERE st_contains (p.geom,c.geom)
    GROUP BY 1
    ORDER BY 3 desc) t1
ON (p.pk_elem = t1.pk_elem);
SELECT RecoverGeometryColumn('areeComputo', 'geom', 4326, 'POLYGON', 'XY');

-- elimino le tabelle inutili

DROP TABLE "tmp_union_boundary";
DROP TABLE "tmp_union_boundary_elem";
DROP TABLE "tmp_Aree";
DROP TABLE "tmp_Aree_elem";
DROP TABLE "tmp_Aree_elem_pulito";
DROP TABLE "centroid_Inner";

-- ottimizzo database

UPDATE geometry_columns_statistics set last_verified = 0;
SELECT UpdateLayerStatistics('geometry_table_name');
VACUUM;
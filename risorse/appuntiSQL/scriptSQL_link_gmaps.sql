-- ScriptSQL da lanciare in SpatiaLite_gui >=4.3a

-- Creo tabella e aggiungo dati

SELECT DropGeoTable('tp_300_link_gmaps');
CREATE TABLE "tp_300_link_gmaps" AS
SELECT t."pk", t."id", t."range", f."tp_id",
								  f."Tipologia",
								  f."Indirizzo",
								  f."Coordinate",
								  f."UPL",
								  f."UPL_nome",
								  f."Quartiere",
								  f."Circoscrizione",
								  f."id_Quartie",
								  f."CAP",
								  f."indizizzo_link",
								  t."geom"
FROM "tp_300" t, "fontane_indirizzo_link_gmaps" f
WHERE t."id" = f."tp_id";
SELECT RecoverGeometryColumn('tp_300_link_gmaps', 'geom', 4326, 'MULTIPOLYGON', 'XY');

-- dissolvo tutti i perimetri dei poligoni sovrapposti

SELECT DropGeoTable('tmp_union_boundary');
CREATE TABLE "tmp_union_boundary" AS
SELECT  "range",st_union(st_boundary (geom)) as geom
FROM "tp_300_link_gmaps";
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
						t1."Tipologia_s",
						t1."Indirizzo_i",
						t1."Coordinate_s",
						t1."UPLs",
						t1."UPL_nome_s",
						t1."Quartiere_i",
						t1."Circoscrizione_i",
						t1."id_Quartie_s",
						t1."CAPs",
						t1."indirizzo_links",
						p.geom
FROM "tmp_Aree_elem_pulito" p 
JOIN
    (SELECT c.pk_elem AS pk_elem, 
						group_concat(p."Tipologia"," | ") AS "Tipologia_s",
						group_concat(p."Indirizzo"," | ") AS "Indirizzo_i",
						group_concat(p."Coordinate"," | ") AS "Coordinate_s",
						group_concat(p."UPL"," | ") AS "UPLs",
						group_concat(p."UPL_nome"," | ") AS "UPL_nome_s",
						group_concat(p."Quartiere"," | ") AS "Quartiere_i",
						group_concat(p."Circoscrizione"," | ") AS "Circoscrizione_i",
						group_concat(p."id_Quartie"," | ") AS "id_Quartie_s",
						group_concat(p."CAP"," | ") AS "CAPs",
						group_concat(p."indizizzo_link"," | ") AS "indirizzo_links",
						count(*) AS nro, 
						group_concat(REPLACE("tp_id",'tp_','')) AS ids 
    FROM centroid_inner c, tp_300_link_gmaps p
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
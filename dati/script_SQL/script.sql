-- Creo tabella con geometria punti

CREATE TABLE "fontanellePalermoAMAP"
("pk_uid" integer PRIMARY KEY autoincrement NOT NULL,
"nome" TEXT, "indirizzo" TEXT, "coordinate" TEXT, "X" DOUBLE, "Y" DOUBLE);

SELECT AddGeometryColumn ('fontanellePalermoAMAP','geom',4326,'POINT','XY');

INSERT INTO "fontanellePalermoAMAP" ("pk_uid","nome","indirizzo","coordinate","X","Y","geom")
SELECT "PK_UID","Nome","Indirizzo","Coordinate","X","Y",MakePoint(CAST(X AS DOUBLE), CAST(Y AS DOUBLE),4326)
FROM "Mappa-Fontanelle-di-Palermo";

-- Creo Voronoi ritagliato con i limiti centro abitato

CREATE TABLE tmp_VoronoiFontanelle AS
SELECT "PK_UID", ST_VoronojDiagram(st_collect(ST_transform(geom,3004)),0,25.0) as geom 
FROM "fontanellePalermoAMAP";
SELECT RecoverGeometryColumn('tmp_VoronoiFontanelle','geom',3004,'MULTIPOLYGON','XY');

SELECT ElementaryGeometries( 'tmp_VoronoiFontanelle','geom','tmp_VoronoiFontanellePA' ,'out_pk' , 'out_multi_id', 1 );

CREATE TABLE tmp_LimitiCentroAbQuartieri AS
SELECT pk, ST_transform(ST_Union (geom),3004) AS geom FROM centroAbitatoQuartieri;
SELECT RecoverGeometryColumn('tmp_LimitiCentroAbQuartieri','geom',3004,'POLYGON','XY');

CREATE TABLE VoronoiFontanelleAMAP_CentroAb AS
SELECT out_pk AS pk_uid, CastToMultiPolygon(ST_Intersection(v.geom,q.geom)) AS geom
FROM tmp_VoronoiFontanellePA v, tmp_LimitiCentroAbQuartieri q;
SELECT RecoverGeometryColumn('VoronoiFontanelleAMAP_CentroAb','geom',3004,'MULTIPOLYGON','XY');

-- 

CREATE TABLE tmp_centroAbQuaDensita AS
SELECT pk,QUA_ID, sum_pop2018/(ST_Area(geom)/1000000) as densita, ST_Transform(geom,3004) as geom
FROM centroAbitatoQuartieri;
SELECT RecoverGeometryColumn('tmp_centroAbQuaDensita','geom',3004,'MULTIPOLYGON','XY');

CREATE TABLE tmp_centroAbQuaVoronoiDensita AS
SELECT pk_uid,QUA_ID, densita, CastToMultiPolygon(ST_Intersection (c.geom, v.geom)) AS geom
FROM tmp_centroAbQuaDensita c,VoronoiFontanelleAMAP_CentroAb v
WHERE st_iNTERSECTS (c.geom, v.geom) = 1;
SELECT RecoverGeometryColumn('tmp_centroAbQuaVoronoiDensita','geom',3004,'MULTIPOLYGON','XY');

CREATE TABLE tmp_centroAbQuaVoronoiDensitaInv AS
SELECT pk_uid,QUA_ID, densita, densita*(ST_Area(geom)/1000000) AS pop1, geom
FROM tmp_centroAbQuaVoronoiDensita;
SELECT RecoverGeometryColumn('tmp_centroAbQuaVoronoiDensitaInv','geom',3004,'MULTIPOLYGON','XY');


CREATE TABLE popPotenzialeFontanelleQuartieri AS
SELECT pk_uid,QUA_ID, Sum (pop1) AS popPot2018 ,CastToMultiPolygon(ST_Union(geom)) AS geom
FROM tmp_centroAbQuaVoronoiDensitaInv
GROUP BY 1;
SELECT RecoverGeometryColumn('popPotenzialeFontanelleQuartieri','geom',3004,'MULTIPOLYGON','XY');


DROP TABLE tmp_VoronoiFontanelle;
DROP TABLE tmp_VoronoiFontanellePA;
DROP TABLE tmp_LimitiCentroAbQuartieri;
DROP TABLE tmp_centroAbQuaDensita;
DROP TABLE tmp_centroAbQuaVoronoiDensita;
DROP TABLE tmp_centroAbQuaVoronoiDensitaInv;


--
-- aggiorno statistiche e VACUUM
--
UPDATE geometry_columns_statistics set last_verified = 0;
SELECT UpdateLayerStatistics('geometry_table_name');
VACUUM;
## descrizione cartelle/file

- ISTAT - Circoscrizioni.geojson
- ISTAT - Quartiere.geojson
- ISTAT - UPL.geojson
- Sezioni Censuarie con info territorio.geojson
- db_territorio_palermo.sqlite

Ho creato, grazie ai dataset di @gbvitrano, un database sqlite cosi strutturato:

![image](https://user-images.githubusercontent.com/7631137/64490465-456be080-d25d-11e9-8533-ab04cd67f627.png)

ho aggiunto altri dataset, di seguito una breve descrizione:

1. `Fontanelle_Palermo_AMAP` : tabella con geometria puntuale ricevuta dall'AMAP
2. `ISTAT_Circoscrizioni` : tabella con geometria poligonale (MultiPolygon)  che rappresenta le circoscrizioni di Palermo;
3. `ISTAT_Quartieri` : tabella con geometria poligonale (MultiPolygon)  che rappresenta i quartieri di Palermo;
4. `ISTAT_SezioneCensuarie2011` : tabella con geometria poligonale (MultiPolygon)  che rappresenta le sezioni censuarie 2011 di Palermo - [link descrizione dati](https://www.istat.it/it/files/2013/11/2015.04.28-Descrizione-dati-Pubblicazione.pdf);
5. `ISTAT_UPL` : tabella con geometria poligonale (MultiPolygon)  che rappresenta le UPL di Palermo;
6. `R19_indicatori_2011_sezioni` : tabella senza geometria che rappresenta gli Indicatori 2011 delle sezioni (vedi punto 4);
7. `UPL_popolazione_residente2018` : tabella senza geometria che rappresenta la popolazione residente UPL(vedi punto 5).
8. `tracciato_2011_sezioni` : tabella senza geometria con le definizioni dei campi (vedi punto 4) [link alla risorsa](https://www.istat.it/it/archivio/104317);

## view spatialite 

per calcoli issue [#26](https://github.com/opendatasicilia/FontanellePalermo/issues/26)

- view conteggio fontanelle circoscrizioni

```sql
CREATE VIEW "v_conteggio_fontanelle_circoscrizione" AS
SELECT c.pk AS pk, c.circoscrizione AS Circoscrizione, count(*) AS nro_fontanelle, c.geom AS geom
FROM "Fontanelle_Palermo_AMAP" f, "ISTAT_Circoscrizioni" c
WHERE ST_intersects (f.geom, c.geom) = 1
GROUP BY 1
ORDER BY 2;

INSERT INTO views_geometry_columns
(view_name, view_geometry, view_rowid, f_table_name, f_geometry_column, read_only)
VALUES ('v_conteggio_fontanelle_circoscrizione', 'geom', 'rowid', 'istat_circoscrizioni', 'geom',1);
```

- view popolazione circoscrizioni
  
```sql
CREATE VIEW "v_pop_residente_2018_circoscrizioni" AS
SELECT u.circoscrizione AS Circoscrizione,p.anno,SUM("SUM di Residenti") AS Residenti,ST_Union(u.geom) AS geom
FROM "ISTAT_UPL" u JOIN "UPL_popolazione_residente2018" p USING (UPL)
GROUP BY 1;

INSERT INTO views_geometry_columns
(view_name, view_geometry, view_rowid, f_table_name, f_geometry_column, read_only)
VALUES ('v_pop_residente_2018_circoscrizioni', 'geom', 'rowid', 'istat_upl', 'geom',1);
```

- view conteggio fontanelle e popolazione circoscrizioni
  
```sql
CREATE VIEW "v_pop_residente_2018_fontanelle_circoscrizioni" AS
SELECT c.circoscrizione AS Circoscrizione, 
		nro_fontanelle, residenti AS Residenti2018,
		ST_Area(ST_Transform(c.geom, 3004))/10000 AS "Area[ha]",
		c.geom AS geom
FROM "v_conteggio_fontanelle_circoscrizione" f 
JOIN "v_pop_residente_2018_circoscrizioni" c 
USING (circoscrizione);

INSERT INTO views_geometry_columns
(view_name, view_geometry, view_rowid, f_table_name, f_geometry_column, read_only)
VALUES ('v_pop_residente_2018_fontanelle_circoscrizioni', 'geom', 'rowid', 'istat_upl', 'geom',1);
```

- view popolazione fontanelle e area sezioni
  
```sql
CREATE VIEW "v_popTot2011_fontanelle_sezioni" AS
SELECT t1.sez2011, t1."nro_fontanelle" AS "nro_fontanelle",r.P1 AS "PopTot2011",t1."Area[ha]" AS "Area[ha]", c.geom AS geom
FROM 
(SELECT sez2011, count(*) AS nro_fontanelle, ST_Area(ST_Transform(c.geom, 3004))/10000 AS "Area[ha]",c.geom
FROM "Fontanelle_Palermo_AMAP" f, "ISTAT_SezioneCensuarie2011" c
WHERE ST_intersects (f.geom, c.geom) = 1 AND loc < 30000
GROUP BY 1) t1
JOIN "R19_indicatori_2011_sezioni" r ON (t1.sez2011 = r.SEZ2011);

INSERT INTO views_geometry_columns
(view_name, view_geometry, view_rowid, f_table_name, f_geometry_column, read_only)
VALUES ('v_poptot2011_fontanelle_sezioni', 'geom', 'rowid', 'istat_sezionecensuarie2011', 'geom',1);
```

--

https://github.com/opendatasicilia/FontanellePalermo/blob/master/risorse/territorio_palermo/db_territorio_palermo.sqlite


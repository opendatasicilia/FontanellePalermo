## Progetto base QGIS

descrizione progetto ...

## Analisi

L'intero processo si basa sui poligoni di [Voronoi](https://it.wikipedia.org/wiki/Diagramma_di_Voronoi) determinati a partire dai punti fontanelle; ogni poligono rappresenterà l'area di competenza della fontanella ovvero l'insieme di tutti i punti più vicini alla fontanella stessa.

Nota la popolazione residente per ogni quartiere (anno 2018), determino uno strato **one-person-one-dot** generato dal classico processo dei **punti casuali nel poligono** (punti casuali nella distribuzione spaziale ma di numero definito); successivamnete, attraverso un altro processo molto famoso **conta punti nel poligono**, determino il numero di persone che ricadono in ogni poligono di Voronoi, questo numero rappresenterà la popolazione potenziale, ovvero, quella popolazione che per raggiungere la fontanella percorrerebbe meno spazio in linea retta.

### Approssimazione quartiere

Prima analisi con grado di approssimanione a livello di quartiere, cioè come se l'intera popolazione residente fosse equamente distribuita sull'intero quartiere.



**Workflow**

1. determino limiti amministrativi comune di Palermo dissolvendo tutto a partire dallo strato `quartieriPalermo`;
2. determino i `poligoniVoronoi`  usando lo strato fontanellePalermo;
3. ritaglio lo strato `poligoniVoronoi` con lo strato `fontanellePalermo` ottenendo `voronoiRitagliato`;
4. genero lo strato `one-person-one-dotQuartieri` puntuale utilizzando il geo-algoritmo `punti casuali dentro poligoni` a partire dallo strato `quartieriPalermo` in cui è presente un campo `sum_pop2018`(quest'ultimo ottenuto dal file csv _Palermo, popolazione residente per cittadinanza, UPL , Quartiere e Circoscrizione - 2018_ scaricato da [qui](https://data.world/gbvitrano/popolazione-residente-a-palermo-upl));
5. genero strato poligonale con geo-algoritmo `conta punti nel poligono` applicato tra lo strato `voronoiRitagliato` e lo strato `one-person-one-dotQuartieri` ottenendo lo strato poligonale `popolazione_fontanelle`;
6. genero lo strato `one-person-one-dotVoronoiFontanelle` puntuale utilizzando il geo-algoritmo `punti casuali dentro poligoni` a partire dallo strato `popolazione_fontanelle` in cui è presente un campo `pop2018`

Ho creato un modello grafico che realizza i punti sopra descritti: genera due file temporanei di output `popolazione_fontanelle`  e `one-person-one-dotVoronoiFontanelle` (occorre salvarli per conservarli nel tempo) 

PS. il modello è salvato nel progetto, cercatelo tra gli strumenti di Processing gruppo `Modelli di progetto`

![screen](./imgs/processo.png)

**Output:**

![screen](./imgs/quartieri.png)

### Approssimazione centro abitato quartiere

Seconda analisi con grado di approssimanione a livello di centro abitato dei quartiere, cioè come se l'intera popolazione residente fosse equamente distribuita solo nel centro abitato dei quartiere.

Il processo e il modello sono gli stessi di quello di sopra cambia solo lo strato o meglio viene considerato solo il centro abitato dei quartieri e non l'intero quartiere.

![screen](./imgs/processo2.png)

**Output:**

![screen](./imgs/CentroAbitatoQuartieri.png)

Confronto:

![screen](./imgs/Confronto.png)
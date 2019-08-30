- [Introduzione](#introduzione)
- [Isolinee](#isolinee)
  - [Calcolo tramite le API di here](#calcolo-tramite-le-api-di-here)
    - [Isocrone](#isocrone)

# Introduzione

In questa cartella saranno inseriti gli output di alcune analisi

# Isolinee

Nella cartella [`isolinee`](./isolinee) si trovano gli elementi per rispondere a questo tipo di domanda:

quali sono le **aree di Palermo** da cui si può **raggiungere** una fontanella in **10** e **5** **minuti** a **piedi**??

## Calcolo tramite le API di here

`here` mette a dispozione delle API con le quali è possibile calcolare isolinee per tempo o per distanza: <https://developer.here.com/documentation/routing/topics/example-isoline-simple-time.html>.

Per usarle è necessario creare un account; con l'[abbonamento freemium](https://developer.here.com/blog/our-here-freemium-developer-plan-in-detail) con cui è possibile eseguire 250.000 transazioni al mese.

**Nota bene**: gli *output* delle API non sono open data, perché impogono il riuso su loro basi/prodotti (vedi sotto).

![](./isolinee/imgs/hereTOS.png)

### Isocrone

Il calcolo delle isocrone - isolinee per intervalli temporali - viene fatta con una chiamata di questo tipo:

```
https://isoline.route.api.here.com/routing/7.2/calculateisoline.json
?app_id=XXXXXXXX
&app_code=XXXXXXXX
&mode=fastest;pedestrian;traffic:disabled
&rangetype=time
&destination=geo!37.1354,13.4521
&range=300,600
```

Alcune note:

- `app_id` e `app_code` sono delle "chiavi" di accesso, e ogni utente ha le proprie;
- con `mode` si imposta la modalità di calcolo. `fastest;pedestrian;traffic:disabled` è il percorso più rapido, fatto a piedi, senza tenere conto del traffico;
- `rangetype`, per il tipo di *range* su cui fare il calcolo. In questo caso è il tempo;
- `destination`, per impostare il punto di destinazione, per calcolare da quali aree è raggiungibile in un determinato tempo;
- `range`, per impostare gli intervalli di tempo per cui si vuole eseguire il calcolo.

L'output è in JSON. [Qui](./isolinee/rawdata/tp_001.json) un *file* di esempio.

È stato creato uno [*script* bash](./isolinee/isolinee.sh) che per [ogni fontana](./isolinee/source.tsv) di acqua potabile di Palermo, calcola le aree da cui è possibile raggiungerle in [10](./isolinee/tp_600.geojson) e [5 minuti](./isolinee/tp_300.geojson).

Qui sotto un'immagine che da un'idea dell'output:

![](./isolinee/imgs/tp_300_600.png)

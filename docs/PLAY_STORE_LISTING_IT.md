# DadaFinanza — scheda Google Play

Documento operativo per la prima pubblicazione. Aggiornare questo file insieme alla release candidata.

## Identità

- **Nome app:** DadaFinanza
- **Package:** `com.dadafinanza.app`
- **Categoria suggerita:** Finanza
- **Versione candidata:** `1.7.0` (base build `+19`; il workflow production assegna un versionCode univoco)
- **Target Android:** API 36
- **Sviluppatore:** DDone

## Descrizione breve

Gestisci spese, entrate, conti e budget in modo semplice, privato e locale.

## Descrizione completa

DadaFinanza è un'app di finanza personale pensata per registrare e capire le proprie spese senza trasformare ogni operazione in un processo complicato.

Registra rapidamente entrate, spese e trasferimenti, organizza i movimenti con conti, categorie, tag e note e controlla il quadro generale dalla Home.

Funzioni principali:

- conti multipli e trasferimenti;
- categorie personalizzabili con icone e colori;
- budget, obiettivi e analisi delle spese;
- movimenti ricorrenti, regole e preset rapidi;
- anticipi e gestione delle somme da ricevere o restituire;
- Smart Suggestions basate sullo storico locale;
- inserimento vocale opzionale;
- widget Android per saldo e azioni rapide;
- ricevute e allegati locali;
- esportazione e importazione CSV;
- backup completo, anche protetto con password;
- blocco dell'app tramite biometria o PIN;
- modalità per nascondere saldi e contenuti sensibili.

DadaFinanza è progettata local-first: i dati finanziari vengono conservati sul dispositivo e non è necessario creare un account.

Il riconoscimento vocale preferisce l'elaborazione sul dispositivo quando supportata. Se viene abilitato il recognizer di sistema, la gestione di audio o testo può dipendere dal servizio vocale configurato su Android.

## Privacy policy

Documento repository:

`docs/PRIVACY_POLICY.md`

URL pubblico provvisorio:

https://github.com/andreadada-dev/dadafinanza/blob/main/docs/PRIVACY_POLICY.md

Per la pubblicazione definitiva è preferibile esporre la stessa informativa anche su una pagina web stabile del dominio DDone.

## Permessi Android — motivazione

| Permesso | Uso |
| --- | --- |
| Fotocamera | Foto/ricevute aggiunte volontariamente ai movimenti |
| Microfono | Inserimento vocale opzionale |
| Biometria | Blocco locale dell'app tramite API di sistema |
| Notifiche | Promemoria e avvisi locali |
| Avvio completato | Ripristino delle notifiche locali pianificate dopo riavvio |
| Vibrazione | Feedback aptico e notifiche |

I permessi devono essere richiesti in modo contestuale, quando la funzione viene usata, e non anticipatamente senza necessità.

## Data Safety — guida alla compilazione

In base all'implementazione corrente:

- nessun account DadaFinanza;
- nessun backend DadaFinanza;
- nessun SDK pubblicitario;
- nessun SDK analytics di terze parti;
- dati finanziari e allegati gestiti localmente;
- export e backup avviati dall'utente;
- il recognizer di sistema, se abilitato, può coinvolgere il fornitore configurato sul dispositivo.

Prima dell'invio definitivo, ricontrollare la sezione Data Safety rispetto al bundle realmente caricato e alle policy correnti di Google Play.

## Asset ancora da produrre/verificare

- icona Play Store 512×512;
- feature graphic 1024×500;
- almeno 2 screenshot telefono;
- eventuali screenshot tablet se dichiarato il supporto;
- email/contatto sviluppatore in Play Console;
- URL privacy stabile;
- classificazione contenuti;
- dichiarazione target audience;
- Data Safety;
- accesso app: nessun login richiesto.

## Release

Per Google Play usare esclusivamente l'AAB prodotto dal workflow:

`.github/workflows/build-production-aab.yml`

Il workflow richiede sempre una firma di produzione e non accetta un fallback alla chiave debug. Usa i secret GitHub quando presenti; altrimenti usa il signing vault persistente del runner in `/builds/dadafinanza/signing`, che deve essere conservato e sottoposto a backup sicuro.

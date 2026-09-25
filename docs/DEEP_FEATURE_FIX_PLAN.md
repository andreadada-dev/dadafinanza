# DadaFinanza — Deep feature hardening

Audit tecnico del 24/09/2026. Questo documento è il piano operativo per eliminare divergenze tra feature vecchie e nuove, correggere bug reali e rendere le superfici principali coerenti e testabili.

## Obiettivi

- [x] Una sola superficie Impostazioni canonica, con tutte le preferenze realmente supportate.
- [x] Regole automatiche applicate nell'ordine di priorità configurato.
- [x] Un solo motore per i movimenti ricorrenti, con supporto corretto dei trasferimenti.
- [x] Allegati/ricevute cancellati insieme ai dati che li referenziano.
- [x] Backup senza file allegati orfani.
- [x] Preset resilienti a eliminazione/merge di conti e categorie.
- [x] Migrazioni/schema coerenti tra database nuovo e aggiornato.
- [x] Eliminazione conti non distruttiva e coerente in tutte le schermate.
- [x] CSV più portabile e lossless per note multilinea e tag.
- [x] Valuta configurabile usata anche nei campi di input, notifiche e testi.
- [x] Test automatici dedicati alle feature Settings e ai bug di integrità emersi.

## 1. Impostazioni

### Da cambiare
- [x] Rendere `PersonalSettingsScreen` la schermata canonica.
- [x] Portare nella schermata canonica: valuta, mostra centesimi, primo giorno settimana, inizio mese finanziario, conferma eliminazioni, gestione Conti.
- [x] Mantenere tema, nascondi saldi, privacy locale, notifiche, voce, Smart Suggestions, preset, anticipi, categorie, regole, Personalizza Home, widget Android, backup/CSV, Non assegnato, trasferimenti nelle statistiche e aptica.

### Da togliere
- [x] Eliminare il comportamento divergente della vecchia `SettingsScreen`.
- [x] Eliminare la vecchia entry point Settings duplicata e instradare anche le shell legacy verso `PersonalSettingsScreen`, mantenendo solo le sottoschermate ancora condivise.

## 2. Regole automatiche

- [x] Caricare le regole con `priority DESC, id ASC`.
- [x] Salvare `priority` anche quando si crea una regola.
- [x] Impedire combinazioni tipo/categoria incompatibili.
- [x] Applicare una regola allo storico in una singola transazione DB.
- [x] Verificare crea/modifica/toggle/duplica/test/reorder/apply/delete.

## 3. Ricorrenti

- [x] Eliminare il secondo motore in `AppState._processDueRecurring`.
- [x] Usare solo `RecurringExecutionService`.
- [x] Garantire supporto a spesa, entrata e trasferimento con `toAccountId`.
- [x] Mantenere guard contro catch-up infinito e conti non validi.
- [x] Aggiungere test per trasferimenti ricorrenti.

## 4. Ricevute e allegati

- [x] Cancellare l'allegato quando viene eliminato un movimento.
- [x] Fare cleanup allegati dopo eliminazione conto/cancellazioni massive.
- [x] `Cancella tutti i dati` deve rimuovere anche la directory allegati.
- [x] Prima del backup fare cleanup degli allegati non referenziati.
- [x] Il backup deve includere solo allegati realmente referenziati.

## 5. Preset, categorie e conti

- [x] Quando una categoria viene unita, aggiornare anche `quick_presets.category_id`.
- [x] Quando una categoria viene eliminata, azzerare il riferimento nei preset.
- [x] Quando un conto viene eliminato, azzerare riferimenti preset origine/destinazione.
- [x] Eliminare/archiviare conti con la stessa policy sicura in ogni entry point.
- [x] Non lasciare ricorrenti con `to_account_id` verso un conto eliminato.
- [x] Per split di categorie eliminate, preservare la classificazione rendendola esplicitamente non assegnata oppure impedire la cancellazione distruttiva se esistono split.

## 6. Schema e integrità

- [x] Portare lo schema a una nuova versione.
- [x] Migrazione che ricostruisce/normalizza le tabelle legacy dove le FK non corrispondono allo schema fresh.
- [x] Eseguire `PRAGMA foreign_key_check` nei test/migrazioni critiche.
- [x] Test fresh database + upgrade da versione precedente.

## 7. Valuta

- [x] Eliminare gli euro hardcoded dai campi principali.
- [x] Usare `state.currency` in Quick Add, budget, anticipi, riconciliazione, split, notifiche e soglie.
- [x] Le notifiche devono formattare importi con la valuta selezionata.

## 8. CSV

- [x] Conservare newline e virgolette secondo CSV RFC-style.
- [x] Rendere i tag reversibili anche se contengono il carattere `|` (encoding strutturato per export nuovo, retrocompatibilità in import).
- [x] Test round-trip note multilinea, Unicode, virgole, virgolette e tag speciali.
- [x] Continuare a supportare i CSV già esportati.

## 9. Test e quality gate

- [x] Aggiungere test Settings/persistenza preferenze.
- [x] Aggiungere test priorità regole.
- [x] Aggiungere test applicazione storico atomica.
- [x] Aggiungere test ricorrente transfer.
- [x] Aggiungere test cleanup allegati.
- [x] Aggiungere test preset dopo merge/eliminazione.
- [x] Aggiungere test CSV round-trip.
- [x] Incrementare versione app.
- [x] Format, Analyze, Tests, debug APK tutti verdi sullo stesso HEAD.
- [x] Merge su `main` solo dopo CI verde e verifica della CI del merge.

## 10. Grafico categorie Home / Conti

- [x] Unificare i periodi visibili della torta in `Oggi · Settimana · Mese · Custom`.
- [x] Mostrare sempre `Oggi`, anche quando il periodo non contiene movimenti.
- [x] Aprire la torta su `Oggi` sia nella Home complessiva sia nella Home del singolo conto.
- [x] Se il totale del periodo è zero, mantenere la torta visibile come anello neutro grigio e mostrare `0 €` al centro.
- [x] Passando Spese ↔ Entrate, mantenere il periodo selezionato anche se il nuovo tipo non contiene movimenti.

## Esito implementazione

Implementazione completata sul branch `build/deep-feature-hardening`.

- Schema database: `6`.
- Versione app: `1.6.0+17`.
- Settings canonica e test responsive a 320/360/390/430 dp + testo grande.
- Test dedicati a migration, regole, ricorrenti transfer e fine mese, allegati, preset, CSV, Android widget e persistenza Settings.
- Android widget aggiornati per rispettare la valuta configurata.
- Quality gate finale richiesto: Format, Analyze, Test, debug APK e verifica APK sullo stesso HEAD.

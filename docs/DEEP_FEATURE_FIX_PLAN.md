# DadaFinanza — Deep feature hardening

Audit tecnico del 24/09/2026. Questo documento è il piano operativo per eliminare divergenze tra feature vecchie e nuove, correggere bug reali e rendere le superfici principali coerenti e testabili.

## Obiettivi

- [ ] Una sola superficie Impostazioni canonica, con tutte le preferenze realmente supportate.
- [ ] Regole automatiche applicate nell'ordine di priorità configurato.
- [ ] Un solo motore per i movimenti ricorrenti, con supporto corretto dei trasferimenti.
- [ ] Allegati/ricevute cancellati insieme ai dati che li referenziano.
- [ ] Backup senza file allegati orfani.
- [ ] Preset resilienti a eliminazione/merge di conti e categorie.
- [ ] Migrazioni/schema coerenti tra database nuovo e aggiornato.
- [ ] Eliminazione conti non distruttiva e coerente in tutte le schermate.
- [ ] CSV più portabile e lossless per note multilinea e tag.
- [ ] Valuta configurabile usata anche nei campi di input, notifiche e testi.
- [ ] Test automatici dedicati alle feature Settings e ai bug di integrità emersi.

## 1. Impostazioni

### Da cambiare
- [ ] Rendere `PersonalSettingsScreen` la schermata canonica.
- [ ] Portare nella schermata canonica: valuta, mostra centesimi, primo giorno settimana, inizio mese finanziario, conferma eliminazioni, gestione Conti.
- [ ] Mantenere tema, nascondi saldi, privacy locale, notifiche, voce, Smart Suggestions, preset, anticipi, categorie, regole, Personalizza Home, widget Android, backup/CSV, Non assegnato, trasferimenti nelle statistiche e aptica.

### Da togliere
- [ ] Eliminare il comportamento divergente della vecchia `SettingsScreen`.
- [ ] La vecchia entry point deve diventare solo un wrapper compatibile verso la schermata canonica, senza backup/import/settings duplicati.

## 2. Regole automatiche

- [ ] Caricare le regole con `priority DESC, id ASC`.
- [ ] Salvare `priority` anche quando si crea una regola.
- [ ] Impedire combinazioni tipo/categoria incompatibili.
- [ ] Applicare una regola allo storico in una singola transazione DB.
- [ ] Verificare crea/modifica/toggle/duplica/test/reorder/apply/delete.

## 3. Ricorrenti

- [ ] Eliminare il secondo motore in `AppState._processDueRecurring`.
- [ ] Usare solo `RecurringExecutionService`.
- [ ] Garantire supporto a spesa, entrata e trasferimento con `toAccountId`.
- [ ] Mantenere guard contro catch-up infinito e conti non validi.
- [ ] Aggiungere test per trasferimenti ricorrenti.

## 4. Ricevute e allegati

- [ ] Cancellare l'allegato quando viene eliminato un movimento.
- [ ] Fare cleanup allegati dopo eliminazione conto/cancellazioni massive.
- [ ] `Cancella tutti i dati` deve rimuovere anche la directory allegati.
- [ ] Prima del backup fare cleanup degli allegati non referenziati.
- [ ] Il backup deve includere solo allegati realmente referenziati.

## 5. Preset, categorie e conti

- [ ] Quando una categoria viene unita, aggiornare anche `quick_presets.category_id`.
- [ ] Quando una categoria viene eliminata, azzerare il riferimento nei preset.
- [ ] Quando un conto viene eliminato, azzerare riferimenti preset origine/destinazione.
- [ ] Eliminare/archiviare conti con la stessa policy sicura in ogni entry point.
- [ ] Non lasciare ricorrenti con `to_account_id` verso un conto eliminato.
- [ ] Per split di categorie eliminate, preservare la classificazione rendendola esplicitamente non assegnata oppure impedire la cancellazione distruttiva se esistono split.

## 6. Schema e integrità

- [ ] Portare lo schema a una nuova versione.
- [ ] Migrazione che ricostruisce/normalizza le tabelle legacy dove le FK non corrispondono allo schema fresh.
- [ ] Eseguire `PRAGMA foreign_key_check` nei test/migrazioni critiche.
- [ ] Test fresh database + upgrade da versione precedente.

## 7. Valuta

- [ ] Eliminare gli euro hardcoded dai campi principali.
- [ ] Usare `state.currency` in Quick Add, budget, anticipi, riconciliazione, split, notifiche e soglie.
- [ ] Le notifiche devono formattare importi con la valuta selezionata.

## 8. CSV

- [ ] Conservare newline e virgolette secondo CSV RFC-style.
- [ ] Rendere i tag reversibili anche se contengono il carattere `|` (encoding strutturato per export nuovo, retrocompatibilità in import).
- [ ] Test round-trip note multilinea, Unicode, virgole, virgolette e tag speciali.
- [ ] Continuare a supportare i CSV già esportati.

## 9. Test e quality gate

- [ ] Aggiungere test Settings/persistenza preferenze.
- [ ] Aggiungere test priorità regole.
- [ ] Aggiungere test applicazione storico atomica.
- [ ] Aggiungere test ricorrente transfer.
- [ ] Aggiungere test cleanup allegati.
- [ ] Aggiungere test preset dopo merge/eliminazione.
- [ ] Aggiungere test CSV round-trip.
- [ ] Incrementare versione app.
- [ ] Format, Analyze, Tests, debug APK tutti verdi sullo stesso HEAD.
- [ ] Merge su `main` solo dopo CI verde e verifica della CI del merge.

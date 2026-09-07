from pathlib import Path


def replace_once(path: str, old: str, new: str, label: str) -> None:
    target = Path(path)
    text = target.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly one match in {path}, found {count}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


replace_once(
    "pubspec.yaml",
    "version: 0.4.4+8",
    "version: 0.5.0+9",
    "version bump",
)

replace_once(
    "docs/LINEE_GUIDA_STYLE.md",
    "Mostrare prima i campi frequenti. Campi avanzati sotto progressive disclosure (`Altre opzioni`, `Aggiungi dettagli`). Nota e tag usano input semplici, senza box decorativi pesanti.",
    "Mostrare prima i campi frequenti. Campi avanzati sotto progressive disclosure (`Altre opzioni`, `Aggiungi dettagli`). Nota e tag usano input semplici, senza box decorativi pesanti. Nel Quick Add la descrizione precede i tag: i suggerimenti descrizione/tag sono strisce orizzontali compatte, derivate dallo storico locale, con preferiti/recenti/frequenti e ricerca. La creazione di un tag nuovo deve essere esplicita; varianti di maiuscole, `#`, accenti e spazi non devono creare duplicati logici.",
    "style form rules",
)

replace_once(
    "docs/LINEE_GUIDA_STYLE.md",
    "- `FinanceQuickAction` — `lib/widgets/finance_quick_action.dart`: azioni rapide senza superficie visiva, ad esempio Spesa/Entrata/Trasferisci/Voce.\n- `showIconPicker` — `lib/widgets/ui_helpers.dart`: selezione icone categorizzata.",
    "- `FinanceQuickAction` — `lib/widgets/finance_quick_action.dart`: azioni rapide senza superficie visiva, ad esempio Spesa/Entrata/Trasferisci/Voce.\n- `QuickSuggestionStrip` — `lib/widgets/quick_suggestion_strip.dart`: striscia orizzontale condivisa per suggerimenti rapidi, senza superfici decorative aggiuntive.\n- `TransactionMetadataFields` — `lib/widgets/transaction_metadata_fields.dart`: descrizione + tag del Quick Add con autocomplete, preferiti e catalogo locale; non possiede logica di salvataggio del movimento.\n- `showIconPicker` — `lib/widgets/ui_helpers.dart`: selezione icone categorizzata.",
    "style inventory",
)

replace_once(
    "docs/ARCHITETTURA.md",
    "`TransactionDraft` può contenere tipo, importo in centesimi, conti, categoria, data, nota, tag, sorgente e indicazione di avvio vocale.\n\n### Precedenza dei dati",
    "`TransactionDraft` può contenere tipo, importo in centesimi, conti, categoria, data, nota, tag, sorgente e indicazione di avvio vocale.\n\nDescrizioni e tag rapidi non introducono un nuovo ledger né una seconda forma di apprendimento: `TransactionMetadataSuggestions` costruisce un indice in memoria dallo storico già caricato in `AppState` per frequenza, recenza, canonicalizzazione e autocomplete. I soli preferiti vengono salvati nelle `settings` locali, quindi sono inclusi nel backup completo senza modificare il formato CSV interoperabile o lo schema delle transazioni.\n\n### Precedenza dei dati",
    "architecture metadata index",
)

replace_once(
    "docs/SMART_FINANCE_ENGINE.md",
    "La descrizione viene lowercased, privata di punteggiatura, numeri transazionali isolati e spazi multipli. I token troppo generici vengono ignorati nel confronto. Exact/prefix/contains e Jaccard sui token alimentano la similarità.",
    "La descrizione viene lowercased, privata di punteggiatura, numeri transazionali isolati e spazi multipli. I token troppo generici vengono ignorati nel confronto. Exact/prefix/contains e Jaccard sui token alimentano la similarità. L'autocomplete del Quick Add riusa le stesse convenzioni di normalizzazione ma resta un indice UI derivato dallo storico: non crea nuovi `LearnedPattern`, non modifica le soglie di confidence e non salva movimenti automaticamente.",
    "smart finance autocomplete note",
)

replace_once(
    "test/quick_add_suggestion_test.dart",
    "class FakeLearningDatabase extends AppDatabase {\n  List<LearnedPattern> patterns = const [];\n  final feedbackKinds = <String>[];\n  final suppressions = <String>{};\n",
    "class FakeLearningDatabase extends AppDatabase {\n  List<LearnedPattern> patterns = const [];\n  final feedbackKinds = <String>[];\n  final suppressions = <String>{};\n  final settings = <String, String>{};\n\n  @override\n  Future<String?> getSetting(String key) async => settings[key];\n\n  @override\n  Future<void> setSetting(String key, String value) async {\n    settings[key] = value;\n  }\n",
    "quick add fake settings",
)

print("Applied docs, version and test integration patch")

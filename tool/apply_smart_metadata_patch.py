from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


path = Path("lib/screens/quick_add_page.dart")
text = path.read_text(encoding="utf-8")

text = replace_once(
    text,
    "import '../services/goal_ledger_service.dart';\nimport '../services/voice_input_service.dart';",
    "import '../services/goal_ledger_service.dart';\nimport '../services/transaction_metadata_suggestions.dart';\nimport '../services/voice_input_service.dart';",
    "service import",
)
text = replace_once(
    text,
    "import '../widgets/ui_helpers.dart';",
    "import '../widgets/transaction_metadata_fields.dart';\nimport '../widgets/ui_helpers.dart';",
    "widget import",
)
text = replace_once(
    text,
    "  final tag = TextEditingController();\n",
    "",
    "tag controller",
)
text = replace_once(
    text,
    "      expanded =\n          editing.tags.isNotEmpty ||\n          editing.receiptPath != null ||\n          !editing.includeInAnalytics;",
    "      expanded =\n          editing.receiptPath != null || !editing.includeInAnalytics;",
    "expanded state",
)
text = replace_once(text, "    tag.dispose();\n", "", "tag dispose")

insert_after_amount = """  void _insertAmountOperator(String symbol) {
    final current = amount.value;
    final start = current.selection.isValid
        ? current.selection.start.clamp(0, current.text.length)
        : current.text.length;
    final end = current.selection.isValid
        ? current.selection.end.clamp(0, current.text.length)
        : current.text.length;
    final next = current.text.replaceRange(start, end, symbol);
    amount.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
    amountFocus.requestFocus();
  }
"""
metadata_helpers = insert_after_amount + """

  List<String> _knownTags(AppState state) => {
    for (final transaction in state.transactions) ...transaction.tags,
    ...tags,
  }.toList(growable: false);

  void _mergeCanonicalTags(Iterable<String> values, AppState state) {
    final index = TransactionMetadataSuggestions.buildIndex(state.transactions);
    for (final raw in values) {
      final cleaned = TransactionMetadataSuggestions.cleanTag(raw);
      if (cleaned.isEmpty) continue;
      final value = index.canonicalTag(cleaned) ?? cleaned;
      final key = TransactionMetadataSuggestions.normalizeLookup(value);
      final alreadySelected = tags.any(
        (item) =>
            TransactionMetadataSuggestions.normalizeLookup(item) == key,
      );
      if (!alreadySelected) tags.add(value);
    }
  }
"""
text = replace_once(
    text,
    insert_after_amount,
    metadata_helpers,
    "metadata helpers",
)

text = replace_once(
    text,
    "      _setDefaults();\n      _scheduleSuggestion();",
    "      _setDefaults();\n      final initialTags = [...tags];\n      tags.clear();\n      _mergeCanonicalTags(initialTags, AppScope.of(context));\n      _scheduleSuggestion();",
    "initial tag canonicalization",
)

text = replace_once(
    text,
    "      people: state.people,\n    );",
    "      people: state.people,\n      knownTags: _knownTags(state),\n    );",
    "voice known tags",
)
text = replace_once(
    text,
    "      for (final value in draft.tags) {\n        if (!tags.contains(value)) tags.add(value);\n      }",
    "      _mergeCanonicalTags(draft.tags, state);",
    "voice tags merge",
)
text = replace_once(
    text,
    "      for (final item in current.tags) {\n        if (!tags.contains(item)) tags.add(item);\n      }",
    "      _mergeCanonicalTags(current.tags, state);",
    "smart tags merge",
)

note_block = """            const SizedBox(height: 16),
            TextField(
              controller: note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrizione opzionale',
                hintText: 'Es. LIDL, Spotify, stipendio…',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            if (lastVoiceTranscript != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hai detto: “$lastVoiceTranscript”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
"""
text = replace_once(text, note_block, "", "old note field")

metadata_insert_anchor = """              ],
            ],
            const Divider(height: 1),
            _PickerRow(
              icon: Icons.calendar_today_outlined,
"""
metadata_insert = """              ],
            ],
            const SizedBox(height: 20),
            TransactionMetadataFields(
              noteController: note,
              transactions: state.transactions,
              tags: List<String>.unmodifiable(tags),
              database: state.database,
              onTagsChanged: (values) => setState(() {
                tags
                  ..clear()
                  ..addAll(values);
              }),
            ),
            if (lastVoiceTranscript != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hai detto: “$lastVoiceTranscript”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            _PickerRow(
              icon: Icons.calendar_today_outlined,
"""
text = replace_once(
    text,
    metadata_insert_anchor,
    metadata_insert,
    "metadata field insertion",
)

old_advanced_tags = """                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: tag,
                                decoration: const InputDecoration(
                                  labelText: 'Aggiungi tag',
                                  hintText: 'Es. VacanzaRoma',
                                ),
                                onSubmitted: (_) => _addTag(),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Aggiungi tag',
                              onPressed: _addTag,
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        if (tags.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags
                                  .map(
                                    (value) => InputChip(
                                      label: Text('#$value'),
                                      onDeleted: () =>
                                          setState(() => tags.remove(value)),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 8),
"""
text = replace_once(text, old_advanced_tags, "", "advanced tags")

old_add_tag = """
  void _addTag() {
    final value = tag.text.trim().replaceFirst('#', '');
    if (value.isEmpty || tags.contains(value)) return;
    setState(() {
      tags.add(value);
      tag.clear();
    });
  }
"""
text = replace_once(text, old_add_tag, "", "old add tag method")

levels_anchor = """  DateTime _lastWaveUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  final List<double> _levels = List<double>.filled(_waveBarCount, 0);
"""
levels_new = levels_anchor + "  final VoiceTranscriptAccumulator _transcript = VoiceTranscriptAccumulator();\n"
text = replace_once(text, levels_anchor, levels_new, "voice accumulator field")

text = replace_once(
    text,
    "    if (clearTranscript && mounted) {\n      setState(() {",
    "    if (clearTranscript && mounted) {\n      _transcript.reset();\n      setState(() {",
    "voice accumulator reset",
)

old_result = """          final cleaned = text.trim();
          if (cleaned.isEmpty) return;
          final changed = cleaned != partial.trim();
          setState(() {
            partial = text;
            ready = !finalResult;
            settled = finalResult;
            error = null;
          });
"""
new_result = """          final best = _transcript.update(text, finalResult: finalResult);
          final cleaned = best.trim();
          if (cleaned.isEmpty) return;
          final changed = cleaned != partial.trim();
          setState(() {
            partial = best;
            ready = !finalResult;
            settled = finalResult;
            error = null;
          });
"""
text = replace_once(text, old_result, new_result, "voice result accumulation")

path.write_text(text, encoding="utf-8")
print("Applied smart metadata patch to quick_add_page.dart")

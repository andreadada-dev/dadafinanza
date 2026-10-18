import 'dart:io';
import 'dart:math' as math;

import 'package:balyn/l10n/localized_material.dart';

import '../theme/balyn_palette.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/attachment_service.dart';
import 'ui_helpers.dart';
import 'balyn_shader_system.dart';

/// The transaction is edited in place: no QuickAddPage or nested form route.
/// Changes are committed atomically through AppState.updateTransaction.
class BalynTransactionDetailContent extends StatefulWidget {
  const BalynTransactionDetailContent({
    required this.item,
    required this.onDelete,
    required this.onDuplicate,
    super.key,
  });
  final FinanceTransaction item;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  State<BalynTransactionDetailContent> createState() =>
      _BalynTransactionDetailContentState();
}

class _BalynTransactionDetailContentState
    extends State<BalynTransactionDetailContent> {
  final _amount = TextEditingController();
  final _amountFocus = FocusNode();
  final _note = TextEditingController();
  final _tags = TextEditingController();
  final _attachmentService = AttachmentService();
  TransactionType _type = TransactionType.expense;
  int? _accountId;
  int? _toAccountId;
  int? _categoryId;
  DateTime _date = DateTime.now();
  bool _includeInAnalytics = true;
  bool _removeReceipt = false;
  XFile? _newReceipt;
  bool _saving = false;
  bool _changed = false;
  bool _revealAmount = false;

  @override
  void initState() {
    super.initState();
    _initialize(widget.item);
    _amount.addListener(_markChanged);
    _note.addListener(_markChanged);
    _tags.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_changed && mounted) setState(() => _changed = true);
  }

  void _initialize(FinanceTransaction item) {
    _amount.text = item.amount.toStringAsFixed(2);
    _note.text = item.note ?? '';
    _tags.text = item.tags.join(', ');
    _type = item.type;
    _accountId = item.accountId;
    _toAccountId = item.toAccountId;
    _categoryId = item.categoryId;
    _date = item.date;
    _includeInAnalytics = item.includeInAnalytics;
    _removeReceipt = false;
    _newReceipt = null;
    _changed = false;
  }

  @override
  void didUpdateWidget(covariant BalynTransactionDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.updatedAt != widget.item.updatedAt) {
      _initialize(widget.item);
    }
  }

  @override
  void dispose() {
    _amount.removeListener(_markChanged);
    _note.removeListener(_markChanged);
    _tags.removeListener(_markChanged);
    _amountFocus.dispose();
    _amount.dispose();
    _note.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      );
      _changed = true;
    });
  }

  Future<void> _pickReceipt() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (!mounted || file == null) return;
      setState(() {
        _newReceipt = file;
        _removeReceipt = false;
        _changed = true;
      });
    } catch (e) {
      if (mounted) _error(e.toString());
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final state = AppScope.of(context);
    if (state.isAdvanceProtectedTransaction(widget.item)) {
      _error('Gestisci questo movimento dalla sezione Anticipi.');
      return;
    }
    final amount = Money.parseExpression(_amount.text);
    if (amount == null || amount <= 0) {
      _error('Inserisci un importo valido maggiore di zero.');
      return;
    }
    if (_accountId == null) {
      _error('Seleziona un conto.');
      return;
    }
    if (_type == TransactionType.transfer &&
        (_toAccountId == null || _toAccountId == _accountId)) {
      _error('Un trasferimento richiede due conti diversi.');
      return;
    }
    setState(() => _saving = true);
    String? receipt = _removeReceipt ? null : widget.item.receiptPath;
    String? newlyPersisted;
    try {
      if (_newReceipt != null) {
        newlyPersisted = await _attachmentService.persist(_newReceipt!.path);
        receipt = newlyPersisted;
      }
      final updated = widget.item.copyWith(
        type: _type,
        amount: amount,
        accountId: _accountId,
        toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
        categoryId: _type == TransactionType.transfer ? null : _categoryId,
        date: _date,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        tags: _tags.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList(),
        receiptPath: receipt,
        includeInAnalytics: _includeInAnalytics,
        updatedAt: DateTime.now(),
      );
      await state.updateTransaction(widget.item, updated);
      if (!mounted) return;
      setState(() => _changed = false);
      _error('Movimento aggiornato.');
    } catch (e) {
      if (newlyPersisted != null) {
        await _attachmentService.delete(newlyPersisted);
      }
      if (mounted) _error(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<T?> _select<T>(String title, List<_Choice<T>> choices, T? selected) =>
      showModalBottomSheet<T>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheet) => FractionallySizedBox(
          heightFactor: .64,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: Theme.of(sheet).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final choice in choices)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        leading: choice.icon == null
                            ? null
                            : Icon(choice.icon, size: 20),
                        title: Text(choice.label),
                        trailing: choice.value == selected
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.pop(sheet, choice.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _chooseType() async {
    final next = await _select<TransactionType>('Tipo movimento', [
      for (final t in TransactionType.values) _Choice(t, t.label),
    ], _type);
    if (!mounted || next == null || next == _type) return;
    final state = AppScope.of(context);
    setState(() {
      _type = next;
      if (next != TransactionType.transfer) _toAccountId = null;
      if (next == TransactionType.transfer ||
          !state.categoriesFor(next).any((c) => c.id == _categoryId)) {
        _categoryId = null;
      }
      _changed = true;
    });
  }

  Future<void> _chooseAccount({bool destination = false}) async {
    final state = AppScope.of(context);
    final options = state.accounts
        .where(
          (account) =>
              (!account.isSystem && !account.isArchived && !account.isLocked) ||
              account.id == widget.item.accountId ||
              account.id == widget.item.toAccountId,
        )
        .toList();
    final next = await _select<int>(
      destination ? 'Conto destinazione' : 'Conto',
      [
        for (final a in options)
          if (!destination || a.id != _accountId)
            _Choice(a.id, a.name, accountIcon(a.iconKey)),
      ],
      destination ? _toAccountId : _accountId,
    );
    if (!mounted || next == null) return;
    setState(() {
      if (destination) {
        _toAccountId = next;
      } else {
        _accountId = next;
        if (_toAccountId == next) _toAccountId = null;
      }
      _changed = true;
    });
  }

  Future<void> _chooseCategory() async {
    final state = AppScope.of(context);
    final next = await _select<int>('Categoria', [
      const _Choice(-1, 'Senza categoria', Icons.remove_circle_outline),
      for (final c in state.categoriesFor(_type))
        _Choice(c.id, c.name, categoryIcon(c.iconKey)),
    ], _categoryId ?? -1);
    if (!mounted || next == null) return;
    setState(() {
      _categoryId = next == -1 ? null : next;
      _changed = true;
    });
  }

  Widget _card(List<Widget> children) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? BalynPalette.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(BalynPalette.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        // No horizontal separators: whitespace defines each field.
        child: Column(children: children),
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    VoidCallback? onTap,
    IconData? icon,
    Color? valueColor,
    Key? key,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final editable = onTap != null;
    final ink = valueColor == null
        ? (editable ? scheme.primary : scheme.onSurface)
        : Colors.white;

    Widget trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: ink, size: 15),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ),
        if (editable) ...[
          const SizedBox(width: 6),
          Icon(Icons.edit_outlined, size: 14, color: ink),
        ],
      ],
    );
    if (valueColor != null) {
      trailing = BalynShaderInk(
        seed: valueColor,
        feature: BalynShaderFeature.text,
        motionMultiplier: 5,
        child: trailing,
      );
    }
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                // Keep the pencil adjacent to its value, with no underline.
                child: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textRow({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Key key,
    required bool readOnly,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: key,
              controller: controller,
              readOnly: readOnly,
              maxLines: 1,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: readOnly ? scheme.onSurfaceVariant : scheme.primary,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 26,
                  minHeight: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final account = state.accountById(_accountId);
    final target = state.accountById(_toAccountId);
    final category = state.categoryById(_categoryId);
    final hidden = state.hideBalance || account?.hideBalance == true;
    final protected = state.isAdvanceProtectedTransaction(widget.item);
    final original = state.transactionById(widget.item.refundOfTransactionId);
    final refunded = state.refundsFor(widget.item.id);
    final splits = state.splitsFor(widget.item.id);
    final receipt = _removeReceipt ? null : widget.item.receiptPath;
    final dateLabel = DateFormat(
      'd MMM yyyy, HH:mm',
      AppI18n.intlLocale,
    ).format(_date);

    return ColoredBox(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF111116)
          : const Color(0xFFF6F6F7),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const PageStorageKey('detail-revolut-layout'),
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 30),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic width: the edit icon follows the amount text
                      // instead of being pushed to the far right of the row.
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _amount,
                        builder: (context, amountValue, _) => LayoutBuilder(
                          builder: (context, constraints) {
                            final typeColor = transactionColor(context, _type);
                            final amountStyle =
                                theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  color: Colors.white,
                                ) ??
                                const TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                );
                            final prefix =
                                (_type == TransactionType.expense
                                    ? '−'
                                    : _type == TransactionType.income
                                    ? '+'
                                    : '') +
                                (state.currency == 'EUR'
                                    ? '€'
                                    : state.currency);
                            final prefixPainter = TextPainter(
                              text: TextSpan(text: prefix, style: amountStyle),
                              textDirection: Directionality.of(context),
                              maxLines: 1,
                            )..layout();
                            final numberPainter = TextPainter(
                              text: TextSpan(
                                text: amountValue.text.isEmpty
                                    ? '0'
                                    : amountValue.text,
                                style: amountStyle,
                              ),
                              textDirection: Directionality.of(context),
                              maxLines: 1,
                            )..layout();
                            final prefixWidth = prefixPainter.width;
                            final numberWidth = numberPainter.width;
                            prefixPainter.dispose();
                            numberPainter.dispose();
                            final maxNumberWidth = math.max(
                              52.0,
                              constraints.maxWidth -
                                  prefixWidth -
                                  (hidden ? 34.0 : 0.0) -
                                  40.0,
                            );
                            final fieldWidth = math.min(
                              math.max(52.0, numberWidth + 14),
                              maxNumberWidth,
                            );
                            return Row(
                              children: [
                                Text(
                                  prefix,
                                  style: amountStyle.copyWith(color: typeColor),
                                ),
                                const SizedBox(width: 2),
                                SizedBox(
                                  width: fieldWidth,
                                  child: TextField(
                                    key: const ValueKey('detail-amount'),
                                    focusNode: _amountFocus,
                                    controller: _amount,
                                    readOnly: protected,
                                    obscureText: hidden && !_revealAmount,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: amountStyle.copyWith(
                                      color: typeColor,
                                    ),
                                    decoration: const InputDecoration(
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 7,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (hidden)
                                  IconButton(
                                    tooltip: _revealAmount
                                        ? 'Nascondi importo'
                                        : 'Mostra importo',
                                    icon: Icon(
                                      _revealAmount
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 17,
                                      color: typeColor,
                                    ),
                                    onPressed: () => setState(
                                      () => _revealAmount = !_revealAmount,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                IconButton(
                                  key: const ValueKey('detail-amount-pencil'),
                                  tooltip: 'Modifica importo',
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 17,
                                    color: typeColor,
                                  ),
                                  onPressed: protected
                                      ? null
                                      : () => _amountFocus.requestFocus(),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _note,
                        builder: (context, value, _) => Text(
                          value.text.trim().isEmpty
                              ? category?.name ?? _type.label
                              : value.text.trim(),
                          style: TextStyle(
                            color: transactionColor(context, _type),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      avatar: Icon(
                        Icons.copy_outlined,
                        color: scheme.primary,
                        size: 17,
                      ),
                      backgroundColor: scheme.primary.withValues(alpha: .10),
                      side: BorderSide.none,
                      label: Text(
                        'Duplica',
                        style: TextStyle(color: scheme.primary),
                      ),
                      onPressed: widget.onDuplicate,
                    ),
                    ActionChip(
                      avatar: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.error,
                        size: 17,
                      ),
                      backgroundColor: scheme.error.withValues(alpha: .09),
                      side: BorderSide.none,
                      label: Text(
                        'Elimina',
                        style: TextStyle(color: scheme.error),
                      ),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _card([
                  _detailRow(label: 'Stato', value: 'Registrato'),
                  _detailRow(
                    key: const ValueKey('detail-type'),
                    label: 'Tipo',
                    value: _type.label,
                    valueColor: transactionColor(context, _type),
                    icon: Icons.swap_horiz_rounded,
                    onTap: protected ? null : _chooseType,
                  ),
                  _detailRow(
                    key: const ValueKey('detail-source'),
                    label: _type == TransactionType.transfer ? 'Da' : 'Conto',
                    value: account?.name ?? 'Conto non disponibile',
                    valueColor: account == null
                        ? null
                        : Color(account.colorValue),
                    icon: account == null
                        ? Icons.account_balance_wallet_outlined
                        : accountIcon(account.iconKey),
                    onTap: protected ? null : _chooseAccount,
                  ),
                  if (_type == TransactionType.transfer)
                    _detailRow(
                      key: const ValueKey('detail-target'),
                      label: 'A',
                      value: target?.name ?? 'Seleziona conto',
                      valueColor: target == null
                          ? null
                          : Color(target.colorValue),
                      icon: Icons.east_rounded,
                      onTap: protected
                          ? null
                          : () => _chooseAccount(destination: true),
                    )
                  else
                    _detailRow(
                      key: const ValueKey('detail-category'),
                      label: 'Categoria',
                      value: category?.name ?? 'Senza categoria',
                      valueColor: category == null
                          ? null
                          : Color(category.colorValue),
                      icon: category == null
                          ? Icons.category_outlined
                          : categoryIcon(category.iconKey),
                      onTap: protected ? null : _chooseCategory,
                    ),
                  _detailRow(
                    key: const ValueKey('detail-date'),
                    label: 'Data e ora',
                    value: dateLabel,
                    icon: Icons.event_outlined,
                    onTap: protected ? null : _pickDate,
                  ),
                ]),
                const SizedBox(height: 13),
                _card([
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Escludi dalle analisi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: !_includeInAnalytics,
                    onChanged: protected
                        ? null
                        : (excluded) => setState(() {
                            _includeInAnalytics = !excluded;
                            _changed = true;
                          }),
                  ),
                  if (_type != TransactionType.transfer)
                    _detailRow(
                      label: 'Importo analisi',
                      icon: Icons.analytics_outlined,
                      value: hidden
                          ? '••••'
                          : moneyFor(state, widget.item.amount),
                    ),
                  if (splits.isNotEmpty)
                    _detailRow(
                      label: 'Suddivisioni',
                      value: splits.length.toString() + ' categorie',
                    ),
                ]),
                const SizedBox(height: 13),
                _card([
                  _textRow(
                    label: 'Nota',
                    hint: 'Aggiungi nota',
                    controller: _note,
                    key: const ValueKey('detail-note'),
                    readOnly: protected,
                  ),
                  _textRow(
                    label: 'Tag',
                    hint: 'Aggiungi tag',
                    controller: _tags,
                    key: const ValueKey('detail-tags'),
                    readOnly: protected,
                  ),
                ]),
                const SizedBox(height: 13),
                _card([
                  _detailRow(
                    label: 'Ricevuta',
                    icon: Icons.camera_alt_outlined,
                    value: _newReceipt != null || receipt != null
                        ? 'Sostituisci'
                        : 'Aggiungi',
                    onTap: protected ? null : _pickReceipt,
                  ),
                  if (receipt != null || _newReceipt != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _newReceipt != null
                                ? _ReceiptPreview(file: File(_newReceipt!.path))
                                : FutureBuilder<File?>(
                                    future: _attachmentService.resolve(
                                      receipt!,
                                    ),
                                    builder: (context, snapshot) =>
                                        snapshot.data == null
                                        ? const Text('Ricevuta non disponibile')
                                        : _ReceiptPreview(file: snapshot.data!),
                                  ),
                          ),
                          IconButton(
                            tooltip: 'Rimuovi ricevuta',
                            onPressed: protected
                                ? null
                                : () => setState(() {
                                    _newReceipt = null;
                                    _removeReceipt = true;
                                    _changed = true;
                                  }),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: scheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
                if (original != null ||
                    refunded > 0 ||
                    widget.item.recurringId != null ||
                    splits.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  _card([
                    if (original != null)
                      _detailRow(
                        label: 'Rimborso di',
                        value: '#' + original.id.toString(),
                      ),
                    if (refunded > 0)
                      _detailRow(
                        label: 'Rimborsato',
                        value: hidden ? '••••' : moneyFor(state, refunded),
                      ),
                    if (widget.item.recurringId != null)
                      _detailRow(
                        label: 'Ricorrenza',
                        value: 'Collegata a Pianifica',
                      ),
                    for (final split in splits)
                      _detailRow(
                        label:
                            state.categoryById(split.categoryId)?.name ??
                            'Categoria',
                        value: hidden ? '••••' : moneyFor(state, split.amount),
                      ),
                  ]),
                ],
                if (protected) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Questo movimento è collegato ad Anticipi. '
                    'Gestiscilo dalla sezione Anticipi.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 210),
            child: _changed && !protected
                ? SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
                      child: FilledButton.icon(
                        key: const ValueKey('detail-save'),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('Salva modifiche'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Choice<T> {
  const _Choice(this.value, this.label, [this.icon]);
  final T value;
  final String label;
  final IconData? icon;
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.file});
  final File file;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.file(
      file,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const ListTile(title: Text('Ricevuta non disponibile')),
    ),
  );
}

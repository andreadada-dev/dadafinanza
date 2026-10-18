import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/attachment_service.dart';
import 'ui_helpers.dart';

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
    _amount.dispose();
    _note.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    if (_type != TransactionType.transfer &&
        _categoryId == null &&
        widget.item.categoryId != null) {
      _error('Seleziona una categoria.');
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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accounts = state.accounts
        .where(
          (a) =>
              (!a.isSystem && !a.isArchived && !a.isLocked) ||
              a.id == widget.item.accountId ||
              a.id == widget.item.toAccountId,
        )
        .toList();
    final categories = state.categoriesFor(_type);
    final categoryIds = categories.map((e) => e.id).toSet();
    final accountIds = accounts.map((e) => e.id).toSet();
    final actionColor = theme.colorScheme.error;
    final receipt = _removeReceipt ? null : widget.item.receiptPath;
    return ColoredBox(
      color: dark ? const Color(0xFF101018) : const Color(0xFFF6F7F9),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const ValueKey('detail-amount'),
                  controller: _amount,
                  obscureText:
                      (state.hideBalance ||
                          state.accountById(_accountId)?.hideBalance == true) &&
                      !_revealAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.left,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.7,
                    color: _type == TransactionType.expense
                        ? theme.colorScheme.error
                        : _type == TransactionType.income
                        ? const Color(0xFF4CA980)
                        : theme.colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Importo',
                    prefixText:
                        (_type == TransactionType.expense
                            ? '−'
                            : _type == TransactionType.income
                            ? '+'
                            : '') +
                        state.currency +
                        ' ',
                    border: InputBorder.none,
                    isDense: true,
                    suffixIcon:
                        (state.hideBalance ||
                            state.accountById(_accountId)?.hideBalance == true)
                        ? IconButton(
                            tooltip: _revealAmount
                                ? 'Nascondi importo'
                                : 'Mostra importo',
                            onPressed: () =>
                                setState(() => _revealAmount = !_revealAmount),
                            icon: Icon(
                              _revealAmount
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          )
                        : const Icon(Icons.edit_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _note,
                  builder: (context, value, _) => Text(
                    value.text.trim().isNotEmpty
                        ? value.text.trim()
                        : state.categoryById(_categoryId)?.name ?? _type.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat(
                    'd MMM yyyy, HH:mm',
                    AppI18n.intlLocale,
                  ).format(_date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: _DetailAction(
                  icon: Icons.copy_outlined,
                  label: 'Duplica',
                  onPressed: widget.onDuplicate,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _DetailAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Elimina',
                  destructive: true,
                  onPressed: widget.onDelete,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          _Section(
            title: 'Dettagli movimento',
            children: [
              const ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Stato'),
                trailing: Text('Registrato'),
              ),
              DropdownButtonFormField<TransactionType>(
                key: ValueKey('detail-type-${_type.name}'),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo movimento',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: [
                  for (final kind in TransactionType.values)
                    DropdownMenuItem(value: kind, child: Text(kind.label)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _type = v;
                    if (v != TransactionType.transfer) _toAccountId = null;
                    if (v == TransactionType.transfer ||
                        !state
                            .categoriesFor(v)
                            .any((c) => c.id == _categoryId)) {
                      _categoryId = null;
                    }
                    _changed = true;
                  });
                },
              ),
              DropdownButtonFormField<int>(
                key: ValueKey('detail-source-${_accountId ?? -1}'),
                initialValue: accountIds.contains(_accountId)
                    ? _accountId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Conto',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                isExpanded: true,
                items: [
                  for (final account in accounts)
                    DropdownMenuItem(
                      value: account.id,
                      child: Text(
                        account.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _accountId = value;
                  if (_toAccountId == value) _toAccountId = null;
                  _changed = true;
                }),
              ),
              if (_type == TransactionType.transfer)
                DropdownButtonFormField<int>(
                  key: ValueKey('detail-target-${_toAccountId ?? -1}'),
                  initialValue:
                      accountIds.contains(_toAccountId) &&
                          _toAccountId != _accountId
                      ? _toAccountId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Conto destinazione',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.east_rounded),
                  ),
                  isExpanded: true,
                  items: [
                    for (final account in accounts)
                      if (account.id != _accountId &&
                          !account.isSystem &&
                          !account.isLocked &&
                          !account.isArchived)
                        DropdownMenuItem(
                          value: account.id,
                          child: Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() {
                    _toAccountId = value;
                    _changed = true;
                  }),
                )
              else
                DropdownButtonFormField<int?>(
                  key: ValueKey('detail-category-${_categoryId ?? -1}'),
                  initialValue: categoryIds.contains(_categoryId)
                      ? _categoryId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Senza categoria'),
                    ),
                    for (final category in categories)
                      DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _categoryId = value;
                    _changed = true;
                  }),
                ),
              ListTile(
                key: const ValueKey('detail-date'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Data e ora'),
                subtitle: Text(
                  DateFormat(
                    'd MMM yyyy, HH:mm',
                    AppI18n.intlLocale,
                  ).format(_date),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Dettagli',
            children: [
              TextField(
                key: const ValueKey('detail-note'),
                controller: _note,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
              ),
              TextField(
                key: const ValueKey('detail-tags'),
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tag (separati da virgola)',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Escludi dalle analisi'),
                subtitle: const Text('Ignora il movimento nei grafici'),
                value: !_includeInAnalytics,
                onChanged: (excluded) => setState(() {
                  _includeInAnalytics = !excluded;
                  _changed = true;
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Ricevuta',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _pickReceipt,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(
                        receipt == null && _newReceipt == null
                            ? 'Aggiungi ricevuta'
                            : 'Cambia ricevuta',
                      ),
                    ),
                  ),
                  if (receipt != null || _newReceipt != null)
                    IconButton(
                      tooltip: 'Rimuovi ricevuta',
                      onPressed: () => setState(() {
                        _newReceipt = null;
                        _removeReceipt = true;
                        _changed = true;
                      }),
                      icon: Icon(Icons.delete_outline, color: actionColor),
                    ),
                ],
              ),
              if (_newReceipt != null)
                _ReceiptPreview(file: File(_newReceipt!.path))
              else if (receipt != null)
                FutureBuilder<File?>(
                  future: _attachmentService.resolve(receipt),
                  builder: (context, snapshot) => snapshot.data == null
                      ? const SizedBox.shrink()
                      : _ReceiptPreview(file: snapshot.data!),
                ),
            ],
          ),
          if (state.splitsFor(widget.item.id).isNotEmpty) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Suddivisioni',
              children: [
                const Text('Modifica le suddivisioni dal menu azioni in alto.'),
                for (final split in state.splitsFor(widget.item.id))
                  ListTile(
                    title: Text(
                      state.categoryById(split.categoryId)?.name ?? 'Categoria',
                    ),
                    trailing: Text(moneyFor(state, split.amount)),
                  ),
              ],
            ),
          ],
          if (state.transactionById(widget.item.refundOfTransactionId) !=
                  null ||
              state.refundsFor(widget.item.id) > 0 ||
              widget.item.recurringId != null) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Collegamenti',
              children: [
                if (state.transactionById(widget.item.refundOfTransactionId) !=
                    null)
                  ListTile(
                    dense: true,
                    title: const Text('Rimborso di'),
                    trailing: Text(
                      '#' + widget.item.refundOfTransactionId.toString(),
                    ),
                  ),
                if (state.refundsFor(widget.item.id) > 0)
                  ListTile(
                    dense: true,
                    title: const Text('Rimborsato'),
                    trailing: Text(
                      state.hideBalance
                          ? '••••'
                          : moneyFor(state, state.refundsFor(widget.item.id)),
                    ),
                  ),
                if (widget.item.recurringId != null)
                  const ListTile(
                    dense: true,
                    title: Text('Ricorrenza'),
                    trailing: Text('Collegata a Pianifica'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 23),
          FilledButton.icon(
            key: const ValueKey('detail-save'),
            onPressed: _saving || !_changed ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Salva modifiche'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(53),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  const _DetailAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Material(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 9),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF24242E)
          : Colors.white,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        for (var i = 0; i < children.length; i++) ...[
          if (i != 0)
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: .20),
            ),
          children[i],
        ],
      ],
    ),
  );
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.file});
  final File file;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.file(
      file,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const ListTile(title: Text('Ricevuta non disponibile')),
    ),
  );
}

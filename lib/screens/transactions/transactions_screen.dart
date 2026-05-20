import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/app_database.dart';
import '../../services/analytics_service.dart';
import '../../services/pdf_report_service.dart';
import '../../services/sync_service.dart';
import '../../utils/error_handler.dart';
import '../../app_state.dart';
import 'package:provider/provider.dart';
import '../../widgets/transactions/add_transaction_dialog.dart';
import '../../widgets/transactions/month_year_picker_dialog.dart';
import '../../widgets/transactions/transaction_filters.dart';
import '../../widgets/transactions/transaction_summary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/transactions/transaction_list_item.dart';
import 'recurring_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _allTransactions = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  int _limit = 20;
  bool _hasMore = true;

  // Sync queue monitoring
  StreamSubscription<List<TransactionsTableData>>? _syncSubscription;
  Map<String, String> _syncStatuses = {}; // txId → syncStatus
  int _pendingCount = 0;

  String _filter = 'all';
  String _search = '';
  String _currency = 'JOD';
  String _userName = '';
  bool _generatingPdf = false;
  int? _filterMonth = DateTime.now().month;
  int? _filterYear = DateTime.now().year;

  final ScrollController _scrollController = ScrollController();
  int _lastTransactionVersion = -1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    AnalyticsService.logScreenView('Transactions');
    _load();
    _watchSyncQueue();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final version = context.watch<AppState>().transactionVersion;
    if (_lastTransactionVersion == -1) {
      _lastTransactionVersion = version;
    } else if (version != _lastTransactionVersion) {
      _lastTransactionVersion = version;
      _load(reset: true);
    }
  }

  void _watchSyncQueue() {
    if (kIsWeb) return;
    final db = AppDatabase.instance;
    _syncSubscription =
        (db.select(db.transactionsTable)
              ..where((t) => t.syncStatus.isNotValue('synced')))
            .watch()
            .listen((rows) {
              if (!mounted) return;
              setState(() {
                _syncStatuses = {for (final r in rows) r.id: r.syncStatus};
                _pendingCount = rows.length;
              });
            });
  }

  Future<void> _triggerSync() async {
    if (kIsWeb) return;
    await SyncService.fullSync();
    if (mounted) _load(reset: true);
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && !_loadingMore && _hasMore) {
        _load(reset: false);
      }
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _limit = 20;
          _loading = true;
          _hasError = false;
          _transactions = [];
        });
      }
    } else {
      if (mounted) setState(() => _loadingMore = true);
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final String? start = (_filterMonth != null && _filterYear != null)
          ? DateTime(_filterYear!, _filterMonth!, 1)
              .toIso8601String()
              .split('T')[0]
          : null;
      final String? end = (_filterMonth != null && _filterYear != null)
          ? DateTime(_filterYear!, _filterMonth! + 1, 0)
              .toIso8601String()
              .split('T')[0]
          : null;

      var baseQ = Supabase.instance.client
          .from('transactions')
          .select('*')
          .eq('user_id', user.id);
      if (_filter != 'all') baseQ = baseQ.eq('type', _filter);
      final rangedQ = (start != null && end != null)
          ? baseQ.gte('transaction_date', start).lte('transaction_date', end)
          : baseQ;
      final pagedFuture = rangedQ
          .order('transaction_date', ascending: false)
          .range(
            reset ? 0 : _transactions.length,
            (reset ? 0 : _transactions.length) + _limit - 1,
          );

      if (reset) {
        var totalsQ = Supabase.instance.client
            .from('transactions')
            .select('type, amount')
            .eq('user_id', user.id);
        final totalsFuture = (start != null && end != null)
            ? totalsQ
                  .gte('transaction_date', start)
                  .lte('transaction_date', end)
            : totalsQ;

        final results = await Future.wait<dynamic>([
          Supabase.instance.client
              .from('profiles')
              .select('currency, full_name')
              .eq('id', user.id)
              .single(),
          pagedFuture,
          totalsFuture,
        ]);

        final profile = results[0] as Map<String, dynamic>;
        final data = results[1] as List;
        final allDataForSummary =
            (results[2] as List).cast<Map<String, dynamic>>();

        if (mounted) {
          _currency = profile['currency'] as String? ?? 'JOD';
          _userName =
              (profile['full_name'] as String? ?? '').split(' ').first;
          setState(() {
            _allTransactions = allDataForSummary;
            _transactions = List<Map<String, dynamic>>.from(data);
            _hasMore = data.length == _limit;
          });
        }
      } else {
        final data = await pagedFuture;
        if (mounted) {
          setState(() {
            _transactions.addAll(List<Map<String, dynamic>>.from(data));
            _hasMore = data.length == _limit;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
      if (mounted) {
        ErrorHandler.handle(
          e,
          context: context,
          developerMessage: 'Transactions Load',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _exportCSV() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'settings_exporting'.tr(),
          style: AppTypography.bodyMd,
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final data = await Supabase.instance.client
          .from('transactions')
          .select('*')
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false);

      final list = data as List;
      if (list.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'settings_no_export'.tr(),
                style: AppTypography.bodyMd,
              ),
            ),
          );
        }
        return;
      }

      String csvField(dynamic value) {
        final str = (value ?? '').toString().replaceAll('\n', ' ');
        final safe = RegExp(r'^[=+\-@\t\r]').hasMatch(str) ? "'$str" : str;
        return '"${safe.replaceAll('"', '""')}"';
      }

      final buffer = StringBuffer();
      buffer.writeln(
        [
          csvField('trans_date'.tr()),
          csvField('inv_type'.tr()),
          csvField('${'trans_amount'.tr()} ($_currency)'),
          csvField('trans_category'.tr()),
          csvField('trans_description'.tr()),
        ].join(','),
      );
      for (final tx in list) {
        final type = tx['type'] == 'income'
            ? 'trans_income'.tr()
            : 'trans_expense'.tr();
        final amount = (tx['amount'] as num? ?? 0).toStringAsFixed(2);
        buffer.writeln(
          [
            csvField(tx['transaction_date']),
            csvField(type),
            csvField(amount),
            csvField(tx['category']),
            csvField(tx['description']),
          ].join(','),
        );
      }

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/fajrak_transactions_$ts.csv');
      await file.writeAsString('\u{feff}${buffer.toString()}', encoding: utf8);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'trans_title'.tr(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'error_export'.tr(args: [e.toString()]),
              style: AppTypography.bodyMd,
            ),
          ),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_generatingPdf) return;
    setState(() => _generatingPdf = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final month = _filterMonth ?? now.month;
      final year = _filterYear ?? now.year;

      final debtsRes = await Supabase.instance.client
          .from('debts')
          .select('name, remaining_amount, monthly_payment, auto_deduct')
          .eq('user_id', user.id)
          .eq('is_paid', false);

      const debtCats = ['ديون', 'debts_title', 'Debts'];
      final income = _allTransactions
          .where((t) => t['type'] == 'income')
          .fold(0.0, (a, t) => a + (t['amount'] as num).toDouble());
      final expenses = _allTransactions
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (a, t) => a + (t['amount'] as num).toDouble());
      final debtPayments = _allTransactions
          .where(
            (t) =>
                t['type'] == 'expense' &&
                debtCats.contains(t['category'] as String?),
          )
          .fold(0.0, (a, t) => a + (t['amount'] as num).toDouble());

      await PdfReportService.shareMonthlyReport(
        data: ReportData(
          userName: _userName,
          currency: _currency,
          month: month,
          year: year,
          income: income,
          expenses: expenses,
          debtPayments: debtPayments,
          transactions: _allTransactions,
          debts: List<Map<String, dynamic>>.from(debtsRes),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('pdf_error'.tr(), style: AppTypography.bodyMd),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  /// Builds a flat list interleaving date-header strings with _TxRecord items.
  List<Object> _buildItems(List<Map<String, dynamic>> transactions) {
    final items = <Object>[];
    String? lastDate;
    int txIndex = 0;
    for (final tx in transactions) {
      final date = (tx['transaction_date'] as String? ?? '').substring(0, 10);
      if (date != lastDate) {
        items.add(date);
        lastDate = date;
      }
      items.add(_TxRecord(tx, txIndex));
      txIndex++;
    }
    return items;
  }

  String _dateLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'today'.tr();
    if (d == yesterday) return 'yesterday'.tr();
    if (date.year == now.year) return DateFormat('d MMMM', 'ar').format(date);
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _transactions;
    return _transactions.where((tx) {
      final desc = (tx['description'] ?? '').toString().toLowerCase();
      final cat = (tx['category'] ?? '').toString().toLowerCase();
      return desc.contains(_search) || cat.contains(_search);
    }).toList();
  }

  Future<void> _delete(String id) async {
    final idx = _transactions.indexWhere((t) => t['id'] == id);
    if (idx == -1) return;
    final deleted = Map<String, dynamic>.from(_transactions[idx]);

    // Optimistic remove
    setState(() => _transactions.removeAt(idx));

    try {
      await Supabase.instance.client
          .from('transactions')
          .delete()
          .eq('id', id);
      if (mounted) context.read<AppState>().notifyTransactionChanged();
    } catch (e) {
      // Rollback on network error
      if (mounted) {
        setState(() {
          if (idx <= _transactions.length) {
            _transactions.insert(idx, deleted);
          } else {
            _transactions.add(deleted);
          }
        });
      }
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('trans_deleted'.tr(), style: AppTypography.bodyMd),
        action: SnackBarAction(
          label: 'undo'.tr(),
          textColor: AppColors.accent,
          onPressed: () async {
            try {
              await Supabase.instance.client
                  .from('transactions')
                  .insert(deleted);
              if (mounted) {
                context.read<AppState>().notifyTransactionChanged();
              }
            } catch (_) {}
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showAddDialog({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddTransactionDialog(
        existing: existing,
        onSaved: () => _load(reset: true),
        baseCurrency: _currency,
      ),
    );
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => MonthYearPickerDialog(
        initialMonth: _filterMonth,
        initialYear: _filterYear,
        onApplied: (m, y) {
          setState(() {
            _filterMonth = m;
            _filterYear = y;
          });
          _load(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;
    final listItems = _buildItems(filtered);

    const debtCategories = ['ديون', 'debts_title', 'Debts'];
    final income = _allTransactions
        .where((t) => t['type'] == 'income')
        .fold(0.0, (a, t) => a + (t['amount'] as num).toDouble());
    final expenses = _allTransactions
        .where((t) => t['type'] == 'expense')
        .fold(0.0, (a, t) => a + (t['amount'] as num).toDouble());
    final debtPayments = _allTransactions
        .where(
          (t) =>
              t['type'] == 'expense' &&
              debtCategories.contains(t['category'] as String?),
        )
        .fold(0.0, (a, t) => a + (t['amount'] as num).toDouble());

    final iconColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'trans_title'.tr(),
              style: AppTypography.headingMd.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              'trans_count'.tr(args: [filtered.length.toString()]),
              style: AppTypography.bodySm.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Sync badge — critical status, stays as dedicated icon
          if (_pendingCount > 0)
            Tooltip(
              message: 'sync_pending'.tr(args: [_pendingCount.toString()]),
              child: Badge(
                label: Text(
                  _pendingCount.toString(),
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: AppColors.warning,
                child: IconButton(
                  onPressed: _triggerSync,
                  icon: Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.warning,
                    semanticLabel: 'tooltip_sync'.tr(),
                  ),
                ),
              ),
            ),
          // Overflow menu — recurring, export CSV, export PDF
          PopupMenuButton<_OverflowAction>(
            icon: Icon(
              Icons.more_vert,
              color: iconColor,
              semanticLabel: 'المزيد من الخيارات',
            ),
            onSelected: (action) {
              switch (action) {
                case _OverflowAction.recurring:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecurringScreen()),
                  );
                case _OverflowAction.exportCsv:
                  _exportCSV();
                case _OverflowAction.exportPdf:
                  _generatePdf();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _OverflowAction.recurring,
                child: _OverflowItem(
                  icon: Icons.repeat,
                  label: 'recurring_title'.tr(),
                  color: iconColor,
                ),
              ),
              PopupMenuItem(
                value: _OverflowAction.exportCsv,
                child: _OverflowItem(
                  icon: Icons.download_outlined,
                  label: 'tooltip_export_csv'.tr(),
                  color: iconColor,
                ),
              ),
              PopupMenuItem(
                value: _OverflowAction.exportPdf,
                enabled: !_generatingPdf,
                child: _OverflowItem(
                  icon: Icons.picture_as_pdf_outlined,
                  label: _generatingPdf
                      ? 'settings_exporting'.tr()
                      : 'tooltip_export_pdf'.tr(),
                  color: _generatingPdf ? AppColors.textSecondary : iconColor,
                  trailing: _generatingPdf
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          TransactionSummary(
            income: income,
            expenses: expenses,
            debtPayments: debtPayments,
            currency: _currency,
          ),
          TransactionFilters(
            currentFilter: _filter,
            currentSearch: _search,
            onSearchChanged: (v) {
              setState(() => _search = v.toLowerCase());
            },
            onFilterChanged: (v) {
              setState(() {
                _filter = v;
                _transactions = [];
                _loading = true;
              });
              _load(reset: true);
            },
            onShowDatePicker: _showMonthYearPicker,
            filterMonth: _filterMonth ?? DateTime.now().month,
            filterYear: _filterYear ?? DateTime.now().year,
            onMonthYearChanged: (m, y) {
              setState(() {
                _filterMonth = m;
                _filterYear = y;
              });
              _load(reset: true);
            },
          ),
          Expanded(
            child: _hasError && _transactions.isEmpty
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'error_load_failed'.tr(),
                    subtitle: 'error_check_connection'.tr(),
                    ctaLabel: 'btn_retry'.tr(),
                    onCta: () => _load(reset: true),
                  )
                : _loading && _transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                    child: TransactionShimmer(count: 8),
                  )
                : filtered.isEmpty
                ? EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'trans_empty'.tr(),
                    subtitle: '',
                    ctaLabel:
                        _search.isEmpty ? 'trans_add_first'.tr() : null,
                    onCta:
                        _search.isEmpty ? () => _showAddDialog() : null,
                  )
                : RefreshIndicator(
                    onRefresh: _triggerSync,
                    color: AppColors.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0, 4, 0, 100),
                      // Extra item at end when loading more pages
                      itemCount:
                          listItems.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Load-more shimmer footer
                        if (index == listItems.length) {
                          return const Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0, AppSpacing.xs, 0, 0),
                            child: TransactionShimmer(count: 2),
                          );
                        }

                        final item = listItems[index];
                        if (item is String) {
                          return _DateSectionHeader(
                            label: _dateLabel(item),
                          );
                        }
                        final rec = item as _TxRecord;
                        return SizedBox(
                          height: AppSpacing.listItemHeight,
                          child: TransactionListItem(
                            key: ValueKey(rec.tx['id']),
                            transaction: rec.tx,
                            currency: _currency,
                            onDelete: _delete,
                            onTap: (t) => _showAddDialog(existing: t),
                            syncStatus: _syncStatuses[rec.tx['id']],
                            staggerIndex:
                                rec.txIndex < 6 ? rec.txIndex : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Overflow menu ─────────────────────────────────────────────────────────

enum _OverflowAction { recurring, exportCsv, exportPdf }

class _OverflowItem extends StatelessWidget {
  const _OverflowItem({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style:
                AppTypography.bodyMd.copyWith(color: color),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Data record for interleaved list ─────────────────────────────────────

class _TxRecord {
  const _TxRecord(this.tx, this.txIndex);
  final Map<String, dynamic> tx;
  final int txIndex;
}

// ── Date section header ───────────────────────────────────────────────────

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screenPaddingHorizontal,
        AppSpacing.sm,
        AppSpacing.screenPaddingHorizontal,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

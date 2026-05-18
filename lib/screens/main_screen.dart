import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'reports/reports_screen.dart';
import 'more/more_screen.dart';
import '../widgets/main_screen/main_bottom_nav_bar.dart';
import '../widgets/transactions/add_transaction_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // 0 = Home (Dashboard)

  late final List<bool> _visited;

  static const List<Widget> _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    MoreScreen(),
  ];

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  late final Animation<double> _fabOpacity;

  static const _easeOut = Cubic(0.23, 1, 0.32, 1);

  @override
  void initState() {
    super.initState();
    _visited = List.generate(_screens.length, (i) => i == 0);

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: _easeOut),
    );
    _fabOpacity = CurvedAnimation(parent: _fabController, curve: _easeOut);
    _fabController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadUnreadAlerts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['tab'] is int) {
      final tab = (args['tab'] as int).clamp(0, _screens.length - 1);
      if (tab != _currentIndex) {
        _switchTab(tab);
      }
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  bool get _showFab => _currentIndex != 3; // hide on More tab

  void _switchTab(int index) {
    final wasShowingFab = _showFab;
    setState(() {
      _currentIndex = index;
      _visited[index] = true;
    });
    final nowShowingFab = _showFab;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations) {
      if (nowShowingFab) _fabController.value = 1.0;
      return;
    }
    if (!wasShowingFab && nowShowingFab) {
      _fabController.forward(from: 0.0);
    } else if (wasShowingFab && !nowShowingFab) {
      _fabController.reverse();
    }
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AddTransactionDialog(
        onSaved: () {
          if (mounted) {
            context.read<AppState>().notifyTransactionChanged();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_screens.length, (i) {
          if (!_visited[i]) return const SizedBox.shrink();
          return _screens[i];
        }),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _switchTab,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showFab
          ? AnimatedBuilder(
              animation: _fabController,
              builder: (context, child) => Opacity(
                opacity: _fabOpacity.value,
                child: Transform.scale(
                  scale: _fabScale.value,
                  child: child,
                ),
              ),
              child: _GoldFab(onPressed: _showAddTransaction),
            )
          : null,
    );
  }
}

class _GoldFab extends StatelessWidget {
  const _GoldFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59D4A843), // rgba(212,168,67,0.35)
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF7A5800),
        icon: const Icon(
          Icons.add,
          semanticLabel: 'أضف معاملة / Add Transaction',
        ),
        label: Text(
          'سجّل معاملة / Add Transaction',
          style: AppTypography.labelLg.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7A5800),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/navigation/add_action_sheet.dart';
import 'accounts/accounts_screen.dart';
import 'calendar/calendar_screen.dart';
import 'home/home_screen.dart';
import 'reports/reports_screen.dart';
import 'budgets/budget_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _pages = [
    HomeScreen(),
    CalendarScreen(),
    BudgetListScreen(),
    AccountsScreen(),
    ReportsScreen(),
  ];

  void _openAddActions() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.28),
      backgroundColor: AppColors.surface,
      builder: (context) => const AddActionSheet(),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _openAddActions();
      return;
    }

    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationIndex =
        _selectedIndex >= 2 ? _selectedIndex + 1 : _selectedIndex;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: navigationIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Calendario',
              ),
              NavigationDestination(
                icon: _AddButtonIcon(),
                label: '',
              ),
              NavigationDestination(
                icon: Icon(Icons.track_changes_outlined),
                selectedIcon: Icon(Icons.track_changes),
                label: 'Presupuestos',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Cuentas',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reportes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButtonIcon extends StatelessWidget {
  const _AddButtonIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.cyan, AppColors.blueOtter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }
}

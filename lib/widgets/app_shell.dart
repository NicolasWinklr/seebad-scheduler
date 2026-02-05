// App shell with collapsible sidebar navigation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';

/// Main app shell with sidebar navigation
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.valueOrNull?.email ?? '';

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isCollapsed ? 72 : 260,
            child: _Sidebar(
              isCollapsed: isCollapsed,
              userEmail: userEmail,
              onToggle: () => ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed,
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                _TopBar(userEmail: userEmail),
                // Content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool isCollapsed;
  final String userEmail;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.isCollapsed,
    required this.userEmail,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SeebadColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo area
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Wave logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.waves,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SeebadScheduler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  path: '/dashboard',
                  isCollapsed: isCollapsed,
                ),
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Dienstplan',
                  path: '/dienstplan',
                  isCollapsed: isCollapsed,
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  label: 'Mitarbeiter',
                  path: '/mitarbeiter',
                  isCollapsed: isCollapsed,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Schicht-Einstellungen',
                  path: '/schicht-einstellungen',
                  isCollapsed: isCollapsed,
                ),
                _NavItem(
                  icon: Icons.tune_outlined,
                  label: 'Regeln & Optimierung',
                  path: '/regeln',
                  isCollapsed: isCollapsed,
                ),
                _NavItem(
                  icon: Icons.warning_amber_outlined,
                  label: 'Konflikte',
                  path: '/konflikte',
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),
          // Collapse toggle
          Container(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                color: Colors.white70,
              ),
              tooltip: isCollapsed ? 'Menü erweitern' : 'Menü minimieren',
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isCollapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isActive = currentPath == path;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white70,
                  size: 22,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final String userEmail;

  const _TopBar({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page title
          Text(
            _getPageTitle(GoRouterState.of(context).matchedLocation),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: SeebadColors.primary.withValues(alpha: 0.1),
                child: Text(
                  userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: SeebadColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                userEmail,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Abmelden',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPageTitle(String path) {
    switch (path) {
      case '/dashboard':
        return 'Dashboard';
      case '/dienstplan':
        return 'Dienstplan';
      case '/mitarbeiter':
        return 'Mitarbeiter';
      case '/schicht-einstellungen':
        return 'Schicht-Einstellungen';
      case '/regeln':
        return 'Regeln & Optimierung';
      case '/konflikte':
        return 'Konflikte';
      default:
        return '';
    }
  }
}

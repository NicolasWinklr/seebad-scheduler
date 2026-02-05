// Dashboard screen with KPI cards and preview

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';

/// Dashboard screen with KPIs and quick actions
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(activeEmployeesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Text(
            'Willkommen zurück!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Hier ist eine Übersicht der aktuellen Dienstplanung.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: SeebadColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                     constraints.maxWidth > 800 ? 2 : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.0,
                children: [
                  _KpiCard(
                    title: 'Offene Schichten',
                    value: '—',
                    subtitle: 'Unbesetzte Slots',
                    icon: Icons.event_busy_outlined,
                    color: SeebadColors.warning,
                  ),
                  _KpiCard(
                    title: 'Abdeckungsgrad',
                    value: '—%',
                    subtitle: 'Besetzte Schichten',
                    icon: Icons.check_circle_outline,
                    color: SeebadColors.success,
                  ),
                  _KpiCard(
                    title: 'Regelverletzungen',
                    value: '—',
                    subtitle: 'Konflikte',
                    icon: Icons.warning_amber_outlined,
                    color: SeebadColors.error,
                  ),
                  _KpiCard(
                    title: 'Mitarbeiter',
                    value: employees.when(
                      data: (list) => list.length.toString(),
                      loading: () => '—',
                      error: (_, __) => '0',
                    ),
                    subtitle: 'Aktive Mitarbeiter',
                    icon: Icons.people_outline,
                    color: SeebadColors.primary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Primary CTA and Period info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Generate schedule CTA
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [SeebadColors.primary, SeebadColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SeebadShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                      const SizedBox(height: 16),
                      const Text(
                        'Dienstplan generieren',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Automatische Schichtplanung mit Berücksichtigung aller Regeln und Präferenzen.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/dienstplan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: SeebadColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Zum Dienstplan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Quick actions
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SeebadShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schnellzugriff',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _QuickAction(
                        icon: Icons.person_add_outlined,
                        label: 'Mitarbeiter hinzufügen',
                        onTap: () => context.go('/mitarbeiter'),
                      ),
                      _QuickAction(
                        icon: Icons.settings_outlined,
                        label: 'Schichten konfigurieren',
                        onTap: () => context.go('/schicht-einstellungen'),
                      ),
                      _QuickAction(
                        icon: Icons.warning_outlined,
                        label: 'Konflikte prüfen',
                        onTap: () => context.go('/konflikte'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 7-day preview
          Text(
            'Vorschau: Nächste 7 Tage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                return _DayPreviewCard(date: date);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: SeebadShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: SeebadColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: SeebadColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPreviewCard extends StatelessWidget {
  final DateTime date;

  const _DayPreviewCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isToday ? SeebadColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: SeebadShadows.card,
        border: isToday ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekdays[date.weekday - 1],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.white70 : SeebadColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isToday ? Colors.white : SeebadColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: isToday ? Colors.white.withValues(alpha: 0.3) : SeebadColors.success.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

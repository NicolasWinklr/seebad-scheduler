// Regeln screen - Rules and optimization settings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';

/// Rules and optimization configuration screen
class RegelnScreen extends ConsumerWidget {
  const RegelnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(solverConfigProvider);

    return config.when(
      data: (cfg) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hard rules section
            _SectionCard(
              title: 'Harte Regeln',
              subtitle: 'Diese Einschränkungen werden immer eingehalten',
              icon: Icons.gavel,
              color: SeebadColors.error,
              child: Column(
                children: [
                  _RuleToggle(
                    title: 'Spätschicht zu Frühschicht verboten',
                    subtitle: 'Keine PM-Schicht gefolgt von AM-Schicht am nächsten Tag',
                    value: cfg.forbidLateToEarly,
                    onChanged: (v) {},
                  ),
                  const Divider(),
                  _NumberSetting(
                    title: 'Mindestruhezeit (Stunden)',
                    value: cfg.minRestHours,
                    min: 8,
                    max: 16,
                    onChanged: (v) {},
                  ),
                  const Divider(),
                  _NumberSetting(
                    title: 'Max. Schichten pro Tag pro Mitarbeiter',
                    value: cfg.maxShiftsPerDayPerEmployee,
                    min: 1,
                    max: 3,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Soft weights section
            _SectionCard(
              title: 'Soft-Gewichtungen',
              subtitle: 'Optimierungsprioritäten (0–100)',
              icon: Icons.tune,
              color: SeebadColors.warning,
              child: Column(
                children: [
                  _WeightSlider(
                    title: 'Abdeckung (Ideal erreichen)',
                    value: cfg.weightCoverageIdeal,
                    onChanged: (v) {},
                  ),
                  _WeightSlider(
                    title: 'Unterdeckung (unter Minimum)',
                    value: cfg.weightCoverageUnderMin,
                    onChanged: (v) {},
                  ),
                  _WeightSlider(
                    title: 'Arbeitsstunden-Abweichung',
                    value: cfg.weightHoursDeviation,
                    onChanged: (v) {},
                  ),
                  _WeightSlider(
                    title: 'Soft-Präferenz Verletzung',
                    value: cfg.weightSoftPreference,
                    onChanged: (v) {},
                  ),
                  _WeightSlider(
                    title: 'Blockplanung (zusammenhängende Tage)',
                    value: cfg.weightBlockPlanning,
                    onChanged: (v) {},
                  ),
                  _WeightSlider(
                    title: 'Sonntag-Fairness',
                    value: cfg.weightSundayFairness,
                    onChanged: (v) {},
                  ),
                  _WeightSlider(
                    title: 'Arbeitslast-Glättung',
                    value: cfg.weightWorkloadSmoothing,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sunday targets
            _SectionCard(
              title: 'Sonntag-Ziele',
              subtitle: 'Faire Verteilung der Sonntagsschichten',
              icon: Icons.wb_sunny_outlined,
              color: SeebadColors.success,
              child: Row(
                children: [
                  Expanded(
                    child: _NumberSetting(
                      title: 'Minimum pro Mitarbeiter',
                      value: cfg.sundayTargetMin,
                      min: 0,
                      max: 4,
                      onChanged: (v) {},
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _NumberSetting(
                      title: 'Maximum pro Mitarbeiter',
                      value: cfg.sundayTargetMax,
                      min: 0,
                      max: 6,
                      onChanged: (v) {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Einstellungen gespeichert')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Einstellungen speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: SeebadShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _RuleToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RuleToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberSetting({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SeebadColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  const _WeightSlider({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SeebadColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: SeebadColors.primary),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 200,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

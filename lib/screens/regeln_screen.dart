// Regeln screen - Rules and optimization settings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

/// Rules and optimization configuration screen
class RegelnScreen extends ConsumerStatefulWidget {
  const RegelnScreen({super.key});

  @override
  ConsumerState<RegelnScreen> createState() => _RegelnScreenState();
}

class _RegelnScreenState extends ConsumerState<RegelnScreen> {
  SolverConfig? _editedConfig;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(solverConfigProvider);

    return configAsync.when(
      data: (cfg) {
        _editedConfig ??= cfg;
        final config = _editedConfig!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cfg == SolverConfig.defaults)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SeebadColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SeebadColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: SeebadColors.info),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Es werden aktuell die Standard-Einstellungen verwendet.')),
                      ],
                    ),
                  ),
                ),

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
                      value: config.forbidLateToEarly,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(forbidLateToEarly: v)),
                    ),
                    const Divider(),
                    _NumberSetting(
                      title: 'Mindestruhezeit (Stunden)',
                      value: config.minRestHours,
                      min: 8,
                      max: 16,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(minRestHours: v)),
                    ),
                    const Divider(),
                    _NumberSetting(
                      title: 'Max. Schichten pro Tag pro Mitarbeiter',
                      value: config.maxShiftsPerDayPerEmployee,
                      min: 1,
                      max: 3,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(maxShiftsPerDayPerEmployee: v)),
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
                      subtitle: 'Sorgt dafür, dass die ideale Anzahl an Mitarbeitern pro Schicht erreicht wird.',
                      value: config.weightCoverageIdeal,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(weightCoverageIdeal: v)),
                    ),
                    _WeightSlider(
                      title: 'Unterdeckung vermeiden',
                      subtitle: 'Vermeidet Schichten unter der Mindestbesetzung (sehr wichtig).',
                      value: config.weightCoverageUnderMin,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(weightCoverageUnderMin: v)),
                    ),
                    _WeightSlider(
                      title: 'Arbeitsstunden-Ausgleich',
                      subtitle: 'Versucht jedem Mitarbeiter gleich viele Stunden zu geben (relativ zu %).',
                      value: config.weightHoursDeviation,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(weightHoursDeviation: v)),
                    ),
                    _WeightSlider(
                      title: 'Soft-Präferenz beachten',
                      subtitle: 'Respektiert "Lieber unter der Woche" / "Kein Wochenende" Wünsche.',
                      value: config.weightSoftPreference,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(weightSoftPreference: v)),
                    ),
                    _WeightSlider(
                      title: 'Blockplanung (zusammenhängend)',
                      subtitle: 'Bevorzugt mehrere Tage am Stück statt zerstückelter Schichten.',
                      value: config.weightBlockPlanning,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(weightBlockPlanning: v)),
                    ),
                    _WeightSlider(
                      title: 'Sonntag-Fairness',
                      subtitle: 'Achtet darauf, dass Sonntage gerecht unter allen verteilt werden.',
                      value: config.weightSundayFairness,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(weightSundayFairness: v)),
                    ),
                    _WeightSlider(
                      title: 'Arbeitslast-Glättung',
                      subtitle: 'Verhindert zu viele harte Tage nacheinander.',
                      value: config.weightWorkloadSmoothing,
                      onChanged: (v) => setState(() => _editedConfig = config.copyWith(weightWorkloadSmoothing: v)),
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
                        value: config.sundayTargetMin,
                        min: 0,
                        max: 4,
                        onChanged: (v) => setState(() => _editedConfig = config.copyWith(sundayTargetMin: v)),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _NumberSetting(
                        title: 'Maximum pro Mitarbeiter',
                        value: config.sundayTargetMax,
                        min: 0,
                        max: 6,
                        onChanged: (v) => setState(() => _editedConfig = config.copyWith(sundayTargetMax: v)),
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
                  onPressed: _isSaving ? null : _saveConfig,
                  icon: _isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                  label: const Text('Einstellungen speichern'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Konfiguration konnte nicht geladen werden', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Fehler: $e', style: const TextStyle(color: SeebadColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _seedDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Standard-Werte laden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDefaults() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(settingsRepositoryProvider).seedDefaults();
      // Force refresh (optional, as stream should update)
       ref.invalidate(solverConfigProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_editedConfig == null) return;
    
    setState(() => _isSaving = true);
    try {
      await ref.read(settingsRepositoryProvider).saveSolverConfig(_editedConfig!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Einstellungen gespeichert'), backgroundColor: SeebadColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
  final String? subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  const _WeightSlider({
    required this.title,
    this.subtitle,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14)),
                    if (subtitle != null)
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
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

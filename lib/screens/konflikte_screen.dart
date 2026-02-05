// Konflikte screen - Conflict/violation management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

/// Conflict view screen showing all violations
class KonflikteScreen extends ConsumerStatefulWidget {
  const KonflikteScreen({super.key});

  @override
  ConsumerState<KonflikteScreen> createState() => _KonflikteScreenState();
}

class _KonflikteScreenState extends ConsumerState<KonflikteScreen> {
  String _severityFilter = 'Alle';
  String? _selectedPeriodId;

  @override
  Widget build(BuildContext context) {
    final periods = ref.watch(periodsProvider);

    // Sample violations for demo
    final sampleViolations = [
      _ViolationItem(
        date: DateTime(2025, 6, 17),
        shiftTemplate: 'S-Früh',
        slotIndex: 1,
        employeeName: 'Max Mustermann',
        code: ViolationCode.lateToEarly,
        explanation: 'Ruhezeit zu kurz: nur 8 Stunden seit letzter Schicht',
      ),
      _ViolationItem(
        date: DateTime(2025, 6, 18),
        shiftTemplate: 'Mili',
        slotIndex: 2,
        employeeName: null,
        code: ViolationCode.underMinCoverage,
        explanation: 'Personal unterdeckt: 1 von 2 benötigten Slots besetzt',
      ),
      _ViolationItem(
        date: DateTime(2025, 6, 20),
        shiftTemplate: 'NM-SB',
        slotIndex: 1,
        employeeName: 'Anna Schmidt',
        code: ViolationCode.softPrefWeekend,
        explanation: 'Mitarbeiter hat Präferenz "Kein Wochenende"',
      ),
    ];

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Period selector
              SizedBox(
                width: 200,
                child: periods.when(
                  data: (list) => DropdownButtonFormField<String>(
                    value: _selectedPeriodId,
                    decoration: const InputDecoration(
                      labelText: 'Periode',
                      isDense: true,
                    ),
                    items: list.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.shortLabel),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedPeriodId = v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Fehler'),
                ),
              ),
              const SizedBox(width: 16),
              // Severity filter
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Alle', label: Text('Alle')),
                  ButtonSegment(value: 'Hart', label: Text('Hart')),
                  ButtonSegment(value: 'Weich', label: Text('Weich')),
                ],
                selected: {_severityFilter},
                onSelectionChanged: (s) => setState(() => _severityFilter = s.first),
              ),
              const Spacer(),
              // Summary chips
              _SummaryChip(
                count: 2,
                label: 'Harte Verstöße',
                color: SeebadColors.error,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                count: 1,
                label: 'Weiche Verstöße',
                color: SeebadColors.warning,
              ),
            ],
          ),
        ),
        // Violations list
        Expanded(
          child: sampleViolations.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sampleViolations.length,
                  itemBuilder: (context, index) {
                    final v = sampleViolations[index];
                    
                    // Apply filter
                    if (_severityFilter == 'Hart' && !v.code.isHard) return const SizedBox.shrink();
                    if (_severityFilter == 'Weich' && v.code.isHard) return const SizedBox.shrink();
                    
                    return _ViolationCard(violation: v);
                  },
                ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SeebadColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, size: 64, color: SeebadColors.success),
          ),
          const SizedBox(height: 24),
          Text('Keine Konflikte!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Alle Schichten sind korrekt zugewiesen.',
            style: TextStyle(color: SeebadColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ViolationItem {
  final DateTime date;
  final String shiftTemplate;
  final int slotIndex;
  final String? employeeName;
  final ViolationCode code;
  final String explanation;

  _ViolationItem({
    required this.date,
    required this.shiftTemplate,
    required this.slotIndex,
    this.employeeName,
    required this.code,
    required this.explanation,
  });
}

class _ViolationCard extends StatelessWidget {
  final _ViolationItem violation;

  const _ViolationCard({required this.violation});

  @override
  Widget build(BuildContext context) {
    final isHard = violation.code.isHard;
    final color = isHard ? SeebadColors.error : SeebadColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: SeebadShadows.card,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isHard ? Icons.error : Icons.warning_amber,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        violation.code.labelGerman,
                        style: TextStyle(fontWeight: FontWeight.w600, color: color),
                      ),
                      Text(
                        '${_formatDate(violation.date)} • ${violation.shiftTemplate} • Slot ${violation.slotIndex}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isHard ? 'Hart' : 'Weich',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (violation.employeeName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: SeebadColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(violation.employeeName!),
                      ],
                    ),
                  ),
                Text(
                  violation.explanation,
                  style: const TextStyle(color: SeebadColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/dienstplan'),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Zum Dienstplan springen'),
                    ),
                    const SizedBox(width: 8),
                    if (!isHard)
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Ignorieren'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return '${weekdays[date.weekday - 1]}, ${date.day}.${date.month}.${date.year}';
  }
}

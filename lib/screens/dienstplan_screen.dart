// Dienstplan screen with 2-week grid

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

/// Dienstplan screen with 2-week scheduling grid
class DienstplanScreen extends ConsumerStatefulWidget {
  const DienstplanScreen({super.key});

  @override
  ConsumerState<DienstplanScreen> createState() => _DienstplanScreenState();
}

class _DienstplanScreenState extends ConsumerState<DienstplanScreen> {
  String? _selectedCellKey;

  @override
  Widget build(BuildContext context) {
    final periods = ref.watch(periodsProvider);
    final selectedPeriodId = ref.watch(selectedPeriodIdProvider);
    final templates = ref.watch(activeShiftTemplatesProvider);
    final weekToggle = ref.watch(selectedWeekToggleProvider);

    return Row(
      children: [
        // Left sidebar
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Periode', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    periods.when(
                      data: (list) => DropdownButtonFormField<String>(
                        value: selectedPeriodId,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        hint: const Text('Periode wählen'),
                        items: list.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Row(
                            children: [
                              Expanded(child: Text(p.shortLabel, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              _StatusBadge(status: p.status),
                            ],
                          ),
                        )).toList(),
                        onChanged: (id) => ref.read(selectedPeriodIdProvider.notifier).state = id,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Fehler beim Laden'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Week toggle
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ansicht', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Beide')),
                        ButtonSegment(value: 1, label: Text('Woche 1')),
                        ButtonSegment(value: 2, label: Text('Woche 2')),
                      ],
                      selected: {weekToggle},
                      onSelectionChanged: (set) => ref.read(selectedWeekToggleProvider.notifier).state = set.first,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: selectedPeriodId != null ? () => _generateSchedule() : null,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Dienstplan generieren'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: selectedPeriodId != null ? () => _showExportDialog() : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportieren'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Employee list section
              _EmployeeListSection(),
            ],
          ),
        ),
        // Main grid area
        Expanded(
          child: selectedPeriodId == null
              ? const _EmptyState()
              : _ScheduleGrid(
                  periodId: selectedPeriodId,
                  weekToggle: weekToggle,
                  templates: templates.valueOrNull ?? [],
                  selectedCellKey: _selectedCellKey,
                  onCellSelected: (key) => setState(() => _selectedCellKey = key),
                ),
        ),
        // Right details panel
        if (_selectedCellKey != null)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Colors.grey.shade200)),
            ),
            child: _DetailsPanel(
              cellKey: _selectedCellKey!,
              onClose: () => setState(() => _selectedCellKey = null),
            ),
          ),
      ],
    );
  }

  void _generateSchedule() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SolverProgressDialog(),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Export'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF Export wird vorbereitet...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel Export'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel Export wird vorbereitet...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PeriodStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color(status.color).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.labelGerman,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(status.color),
        ),
      ),
    );
  }
}

class _EmployeeListSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(employeeListExpandedProvider);
    final employees = ref.watch(activeEmployeesProvider);

    return Column(
      children: [
        InkWell(
          onTap: () => ref.read(employeeListExpandedProvider.notifier).state = !isExpanded,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Mitarbeiter', style: TextStyle(fontWeight: FontWeight.w500))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SeebadColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded ? 'Verbergen' : 'Anzeigen',
                        style: const TextStyle(fontSize: 12, color: SeebadColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: SeebadColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: employees.when(
              data: (list) => ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final emp = list[index];
                  return Draggable<Employee>(
                    data: emp,
                    feedback: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: SeebadColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emp.fullName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: SeebadColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: SeebadColors.primary.withValues(alpha: 0.2),
                            child: Text(
                              emp.firstName.isNotEmpty ? emp.firstName[0] : '?',
                              style: const TextStyle(fontSize: 12, color: SeebadColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(emp.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Row(
                                  children: emp.areas.take(2).map((a) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: _getAreaColor(a).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        a.length > 10 ? a.substring(0, 8) : a,
                                        style: TextStyle(fontSize: 9, color: _getAreaColor(a)),
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.drag_indicator, size: 16, color: SeebadColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Fehler')),
            ),
          ),
      ],
    );
  }

  Color _getAreaColor(String area) {
    if (area.contains('Sauna')) return SeebadColors.areaSauna;
    if (area.contains('Mili')) return SeebadColors.areaMili;
    return SeebadColors.areaBad;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Keine Periode ausgewählt',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SeebadColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle eine Periode aus der Seitenleiste um den Dienstplan anzuzeigen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SeebadColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ScheduleGrid extends ConsumerWidget {
  final String periodId;
  final int weekToggle;
  final List<ShiftTemplate> templates;
  final String? selectedCellKey;
  final ValueChanged<String> onCellSelected;

  const _ScheduleGrid({
    required this.periodId,
    required this.weekToggle,
    required this.templates,
    this.selectedCellKey,
    required this.onCellSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    if (period == null) return const _EmptyState();

    final dates = weekToggle == 1 
        ? period.firstWeekDates 
        : weekToggle == 2 
            ? period.secondWeekDates 
            : period.allDates.take(14).toList();

    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final dateFormatter = DateFormat('d.M');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          headingRowHeight: 56,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 80,
          border: TableBorder.all(color: Colors.grey.shade200, width: 1),
          columns: [
            const DataColumn(label: SizedBox(width: 100, child: Text('Schicht', style: TextStyle(fontWeight: FontWeight.w600)))),
            ...dates.map((d) => DataColumn(
              label: Container(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdays[d.weekday - 1],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: (d.weekday == 6 || d.weekday == 7) ? SeebadColors.primary : null,
                      ),
                    ),
                    Text(dateFormatter.format(d), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            )),
          ],
          rows: templates.map((template) => DataRow(
            cells: [
              DataCell(
                Container(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Color(template.areaColor).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          template.area.length > 12 ? '${template.area.substring(0, 10)}...' : template.area,
                          style: TextStyle(fontSize: 10, color: Color(template.areaColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...dates.map((d) {
                final cellKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}#${template.code}';
                final isSelected = cellKey == selectedCellKey;
                return DataCell(
                  DragTarget<Employee>(
                    onAcceptWithDetails: (details) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${details.data.fullName} zu ${template.label} hinzugefügt')),
                      );
                    },
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: () => onCellSelected(cellKey),
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? SeebadColors.primary.withValues(alpha: 0.1)
                                : candidateData.isNotEmpty 
                                    ? SeebadColors.success.withValues(alpha: 0.1)
                                    : null,
                            border: isSelected ? Border.all(color: SeebadColors.primary, width: 2) : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${template.minStaffDefault}/${template.idealStaffDefault}',
                                style: const TextStyle(fontSize: 11, color: SeebadColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: SeebadColors.success.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          )).toList(),
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  final String cellKey;
  final VoidCallback onClose;

  const _DetailsPanel({required this.cellKey, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final parts = cellKey.split('#');
    final dateStr = parts.first;
    final templateCode = parts.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SeebadColors.primary,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      templateCode,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Slots', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _SlotCard(index: 1, employee: null),
              const SizedBox(height: 16),
              Text('Konflikte', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SeebadColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: SeebadColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Keine Konflikte', style: TextStyle(color: SeebadColors.success)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Aktionen', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: false,
                onChanged: (v) {},
                title: const Text('Slot sperren'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: false,
                onChanged: (v) {},
                title: const Text('Gesamte Zelle sperren'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final int index;
  final Employee? employee;

  const _SlotCard({required this.index, this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SeebadColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: SeebadColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SeebadColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: employee != null
                ? Text(employee!.fullName)
                : const Text('Unbesetzt', style: TextStyle(color: SeebadColors.textSecondary, fontStyle: FontStyle.italic)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SolverProgressDialog extends StatefulWidget {
  const _SolverProgressDialog();

  @override
  State<_SolverProgressDialog> createState() => _SolverProgressDialogState();
}

class _SolverProgressDialogState extends State<_SolverProgressDialog> {
  String _status = 'Slots generieren...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _runSolver();
  }

  Future<void> _runSolver() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() { _status = 'Schritt 1/4: Slots generieren...'; _progress = 0.25; });
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _status = 'Schritt 2/4: Mitarbeiter zuweisen...'; _progress = 0.5; });
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _status = 'Schritt 3/4: Konflikte prüfen...'; _progress = 0.75; });
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _status = 'Schritt 4/4: Finalisieren...'; _progress = 1.0; });
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dienstplan wird generiert...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text(_status),
        ],
      ),
    );
  }
}

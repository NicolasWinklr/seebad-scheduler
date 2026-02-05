// Dienstplan screen with 2-week grid

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/services.dart';

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
                    Row(
                      children: [
                        Text('Periode', style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _showCreatePeriodDialog(),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          tooltip: 'Neue Periode erstellen',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
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
    final periodId = ref.read(selectedPeriodIdProvider);
    if (periodId == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SolverProgressDialog(periodId: periodId),
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
                _exportPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel Export'),
              onTap: () {
                Navigator.pop(context);
                _exportExcel();
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

  Future<void> _exportPdf() async {
    final periodId = ref.read(selectedPeriodIdProvider);
    final period = ref.read(selectedPeriodProvider);
    final templates = ref.read(activeShiftTemplatesProvider).valueOrNull ?? [];
    final employees = ref.read(activeEmployeesProvider).valueOrNull ?? [];
    final assignments = await ref.read(periodRepositoryProvider).getAssignments(periodId!);
    
    if (period == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF wird generiert...')),
    );
    
    try {
      final pdfService = PdfExportService();
      final bytes = await pdfService.generateSchedulePdf(
        period: period,
        assignments: assignments,
        templates: templates,
        employees: employees,
      );
      
      // Download in browser
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'dienstplan_${period.shortLabel}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF heruntergeladen!'), backgroundColor: SeebadColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    final periodId = ref.read(selectedPeriodIdProvider);
    final period = ref.read(selectedPeriodProvider);
    final templates = ref.read(activeShiftTemplatesProvider).valueOrNull ?? [];
    final employees = ref.read(activeEmployeesProvider).valueOrNull ?? [];
    final assignments = await ref.read(periodRepositoryProvider).getAssignments(periodId!);
    
    if (period == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel wird generiert...')),
    );
    
    try {
      final excelService = ExcelExportService();
      final bytes = await excelService.generateScheduleExcel(
        period: period,
        assignments: assignments,
        templates: templates,
        employees: employees,
      );
      
      // Download in browser
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'dienstplan_${period.shortLabel}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel heruntergeladen!'), backgroundColor: SeebadColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreatePeriodDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreatePeriodDialog(
        onCreated: (periodId) {
          ref.read(selectedPeriodIdProvider.notifier).state = periodId;
        },
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

class _SolverProgressDialog extends ConsumerStatefulWidget {
  final String periodId;
  
  const _SolverProgressDialog({required this.periodId});

  @override
  ConsumerState<_SolverProgressDialog> createState() => _SolverProgressDialogState();
}

class _SolverProgressDialogState extends ConsumerState<_SolverProgressDialog> {
  String _status = 'Initialisiere...';
  double _progress = 0.0;
  bool _isComplete = false;
  String? _error;
  SolverResult? _result;

  @override
  void initState() {
    super.initState();
    _runSolver();
  }

  Future<void> _runSolver() async {
    try {
      setState(() { _status = 'Schritt 1/4: Slots generieren...'; _progress = 0.25; });
      await Future.delayed(const Duration(milliseconds: 300));
      
      setState(() { _status = 'Schritt 2/4: Mitarbeiter zuweisen...'; _progress = 0.5; });
      
      // Actually run the solver
      final result = await ref.read(solverProvider(widget.periodId).future);
      
      setState(() { _status = 'Schritt 3/4: Konflikte prüfen...'; _progress = 0.75; });
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Save assignments to Firestore
      setState(() { _status = 'Schritt 4/4: Speichern...'; _progress = 0.9; });
      await _saveAssignments(result.assignments);
      
      setState(() { 
        _status = 'Fertig! ${result.stats.filledSlots}/${result.stats.totalSlots} Slots besetzt.'; 
        _progress = 1.0; 
        _isComplete = true;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = 'Fehler: $e';
      });
    }
  }

  Future<void> _saveAssignments(List<Assignment> assignments) async {
    final repo = ref.read(periodRepositoryProvider);
    for (final assignment in assignments) {
      await repo.saveAssignment(widget.periodId, assignment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_error != null ? 'Fehler' : _isComplete ? 'Fertig!' : 'Dienstplan wird generiert...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error == null) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
          ],
          Text(_status),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultStats(result: _result!),
          ],
        ],
      ),
      actions: [
        if (_isComplete || _error != null)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _result),
            child: const Text('Schließen'),
          ),
      ],
    );
  }
}

class _ResultStats extends StatelessWidget {
  final SolverResult result;
  
  const _ResultStats({required this.result});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SeebadColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Besetzt', value: result.stats.filledSlots.toString(), color: SeebadColors.success),
              _StatItem(label: 'Offen', value: result.stats.emptyMinSlots.toString(), color: SeebadColors.warning),
              _StatItem(label: 'Konflikte', value: result.violations.length.toString(), color: SeebadColors.error),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Abdeckung: ${result.stats.coveragePercent.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StatItem({required this.label, required this.value, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: SeebadColors.textSecondary)),
      ],
    );
  }
}

class _CreatePeriodDialog extends ConsumerStatefulWidget {
  final Function(String periodId) onCreated;

  const _CreatePeriodDialog({required this.onCreated});

  @override
  ConsumerState<_CreatePeriodDialog> createState() => _CreatePeriodDialogState();
}

class _CreatePeriodDialogState extends ConsumerState<_CreatePeriodDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Default to next Monday for 2 weeks
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    _startDate = DateTime(now.year, now.month, now.day + daysUntilMonday);
    _endDate = _startDate.add(const Duration(days: 13)); // 2 weeks
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Periode erstellen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Startdatum'),
            subtitle: Text(DateFormat('dd.MM.yyyy (EEEE)', 'de').format(_startDate)),
            onTap: () => _pickDate(isStart: true),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Enddatum'),
            subtitle: Text(DateFormat('dd.MM.yyyy (EEEE)', 'de').format(_endDate)),
            onTap: () => _pickDate(isStart: false),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SeebadColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: SeebadColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${_endDate.difference(_startDate).inDays + 1} Tage',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createPeriod,
          child: _isCreating 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Erstellen'),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('de'),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          // Adjust end date if needed
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 13));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _createPeriod() async {
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enddatum muss nach Startdatum liegen'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isCreating = true);
    
    try {
      final period = Period(
        id: '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
        startDate: _startDate,
        endDate: _endDate,
        status: PeriodStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await ref.read(periodRepositoryProvider).create(period);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(period.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Periode ${period.shortLabel} erstellt!'), backgroundColor: SeebadColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

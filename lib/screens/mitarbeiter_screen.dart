// Mitarbeiter screen - Employee management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

/// Employee management screen
class MitarbeiterScreen extends ConsumerStatefulWidget {
  const MitarbeiterScreen({super.key});

  @override
  ConsumerState<MitarbeiterScreen> createState() => _MitarbeiterScreenState();
}

class _MitarbeiterScreenState extends ConsumerState<MitarbeiterScreen> {
  String _searchQuery = '';
  String? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);

    return Row(
      children: [
        // Main content
        Expanded(
          child: Column(
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
                    // Search
                    SizedBox(
                      width: 300,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Mitarbeiter suchen...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add button
                    ElevatedButton.icon(
                      onPressed: () => _showEmployeeDialog(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Mitarbeiter hinzufügen'),
                    ),
                  ],
                ),
              ),
              // Table
              Expanded(
                child: employees.when(
                  data: (list) {
                    final filtered = list.where((e) => 
                      e.fullName.toLowerCase().contains(_searchQuery) ||
                      e.areas.any((a) => a.toLowerCase().contains(_searchQuery))
                    ).toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: SeebadShadows.card,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DataTable(
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Vertrag')),
                              DataColumn(label: Text('Arbeitsumfang')),
                              DataColumn(label: Text('Bereiche')),
                              DataColumn(label: Text('Aktionen')),
                            ],
                            rows: filtered.map((emp) => DataRow(
                              selected: emp.id == _selectedEmployeeId,
                              onSelectChanged: (_) => setState(() => _selectedEmployeeId = emp.id),
                              cells: [
                                DataCell(Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: emp.isActive 
                                          ? SeebadColors.primary.withValues(alpha: 0.1)
                                          : Colors.grey.shade200,
                                      child: Text(
                                        emp.firstName.isNotEmpty ? emp.firstName[0] : '?',
                                        style: TextStyle(
                                          color: emp.isActive ? SeebadColors.primary : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        if (!emp.isActive)
                                          const Text('Inaktiv', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                )),
                                DataCell(_StatusChip(status: emp.contractStatus)),
                                DataCell(Text(emp.contractWorkPattern.label)),
                                DataCell(Text('${emp.workloadPct}%')),
                                DataCell(Wrap(
                                  spacing: 4,
                                  children: emp.areas.map((a) => _AreaChip(area: a)).toList(),
                                )),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _showEmployeeDialog(emp),
                                      tooltip: 'Bearbeiten',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        emp.isActive ? Icons.visibility_off : Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () => _toggleActive(emp),
                                      tooltip: emp.isActive ? 'Deaktivieren' : 'Aktivieren',
                                    ),
                                  ],
                                )),
                              ],
                            )).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Fehler: $e')),
                ),
              ),
            ],
          ),
        ),
        // Detail drawer
        if (_selectedEmployeeId != null)
          _EmployeeDetailDrawer(
            employeeId: _selectedEmployeeId!,
            onClose: () => setState(() => _selectedEmployeeId = null),
          ),
      ],
    );
  }

  void _showEmployeeDialog(Employee? employee) {
    showDialog(
      context: context,
      builder: (context) => _EmployeeFormDialog(employee: employee),
    );
  }

  Future<void> _toggleActive(Employee emp) async {
    await ref.read(employeeRepositoryProvider).update(emp.copyWith(isActive: !emp.isActive));
  }
}

class _StatusChip extends StatelessWidget {
  final ContractStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      ContractStatus.fixangestellt: SeebadColors.success,
      ContractStatus.teilzeit: SeebadColors.info,
      ContractStatus.ferialer: SeebadColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[status]!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, color: colors[status], fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  final String area;

  const _AreaChip({required this.area});

  @override
  Widget build(BuildContext context) {
    Color color = SeebadColors.areaBad;
    if (area.contains('Sauna')) color = SeebadColors.areaSauna;
    if (area.contains('Mili')) color = SeebadColors.areaMili;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        area.length > 15 ? '${area.substring(0, 12)}...' : area,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}

class _EmployeeDetailDrawer extends ConsumerWidget {
  final String employeeId;
  final VoidCallback onClose;

  const _EmployeeDetailDrawer({required this.employeeId, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider).valueOrNull ?? [];
    final employee = employees.cast<Employee?>().firstWhere((e) => e?.id == employeeId, orElse: () => null);

    if (employee == null) return const SizedBox.shrink();

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: SeebadColors.primary,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    employee.firstName.isNotEmpty ? employee.firstName[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        employee.contractStatus.label,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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
          // Tabs content
          Expanded(
            child: DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    labelColor: SeebadColors.primary,
                    tabs: [
                      Tab(text: 'Allgemein'),
                      Tab(text: 'Bereiche'),
                      Tab(text: 'Zeiten'),
                      Tab(text: 'Abwesenheiten'),
                      Tab(text: 'Notizen'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _GeneralTab(employee: employee),
                        _AreasTab(employee: employee),
                        _TimesTab(employee: employee),
                        _AbsencesTab(employee: employee),
                        _NotesTab(employee: employee),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  final Employee employee;
  const _GeneralTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Vorname', value: employee.firstName),
        _InfoRow(label: 'Nachname', value: employee.lastName),
        _InfoRow(label: 'Aktiv', value: employee.isActive ? 'Ja' : 'Nein'),
        _InfoRow(label: 'Vertragsstatus', value: employee.contractStatus.label),
        _InfoRow(label: 'Arbeitsumfang', value: '${employee.workloadPct}%'),
        _InfoRow(label: 'Vertragsbeginn', value: _formatDate(employee.contractStart)),
        if (employee.contractEnd != null)
          _InfoRow(label: 'Vertragsende', value: _formatDate(employee.contractEnd!)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _AreasTab extends StatelessWidget {
  final Employee employee;
  const _AreasTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bereiche', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: employee.areas.map((a) => Chip(label: Text(a))).toList(),
        ),
        const SizedBox(height: 16),
        _InfoRow(label: 'Vertragsmuster', value: employee.contractWorkPattern.label),
        _InfoRow(label: 'Präferenz', value: employee.softPreference.label),
      ],
    );
  }
}

class _TimesTab extends StatelessWidget {
  final Employee employee;
  const _TimesTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (employee.fixedFreeDay != null)
          _InfoRow(label: 'Fixer freier Tag', value: employee.fixedFreeDay!),
        _InfoRow(label: 'Freie Tage/Woche', value: employee.freeDaysPerWeek.count.toString()),
        const SizedBox(height: 16),
        Text('Zeitbeschränkung', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _InfoRow(label: 'Global', value: employee.timeRestrictions.global.label ?? 'Unbeschränkt'),
      ],
    );
  }
}

class _AbsencesTab extends ConsumerWidget {
  final Employee employee;
  const _AbsencesTab({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Urlaub', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: () => _addVacation(context, ref, employee),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Eintragen'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        if (employee.absences.vacationRanges.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Kein Urlaub eingetragen', style: TextStyle(color: SeebadColors.textSecondary)),
          )
        else
          ...employee.absences.vacationRanges.map((r) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.beach_access, size: 20, color: SeebadColors.primary),
            title: Text('${_formatDate(r.from)} - ${_formatDate(r.to)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _removeVacation(ref, employee, r),
            ),
          )),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sonstige Abwesenheit', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: () => _addShortAbsence(context, ref, employee),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Eintragen'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        if (employee.absences.shortUnavailability.isEmpty)
          const Text('Keine Abwesenheiten', style: TextStyle(color: SeebadColors.textSecondary))
        else
          ...employee.absences.shortUnavailability.map((r) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_busy, size: 20, color: SeebadColors.warning),
            title: Text('${_formatDate(r.from)} - ${_formatDate(r.to)}'),
            subtitle: r.reason != null ? Text(r.reason!) : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _removeShortAbsence(ref, employee, r),
            ),
          )),
      ],
    );
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy', 'de').format(date);

  Future<void> _addVacation(BuildContext context, WidgetRef ref, Employee employee) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('de'),
      helpText: 'Urlaubszeitraum wählen',
    );

    if (range != null) {
      final updatedAbsences = employee.absences.copyWith(
        vacationRanges: [...employee.absences.vacationRanges, DateRange(from: range.start, to: range.end)],
      );
      await _updateEmployee(ref, employee.copyWith(absences: updatedAbsences));
    }
  }

  Future<void> _removeVacation(WidgetRef ref, Employee employee, DateRange range) async {
    final updatedList = List<DateRange>.from(employee.absences.vacationRanges)..remove(range);
    final updatedAbsences = employee.absences.copyWith(vacationRanges: updatedList);
    await _updateEmployee(ref, employee.copyWith(absences: updatedAbsences));
  }

  Future<void> _addShortAbsence(BuildContext context, WidgetRef ref, Employee employee) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('de'),
      helpText: 'Abwesenheit wählen',
    );

    if (range != null) {
      // Optional: Ask for reason
      String? reason; // Simplified for now, could actully show a dialog
      
      final updatedAbsences = employee.absences.copyWith(
        shortUnavailability: [...employee.absences.shortUnavailability, DateRange(from: range.start, to: range.end, reason: reason)],
      );
      await _updateEmployee(ref, employee.copyWith(absences: updatedAbsences));
    }
  }

  Future<void> _removeShortAbsence(WidgetRef ref, Employee employee, DateRange range) async {
    final updatedList = List<DateRange>.from(employee.absences.shortUnavailability)..remove(range);
    final updatedAbsences = employee.absences.copyWith(shortUnavailability: updatedList);
    await _updateEmployee(ref, employee.copyWith(absences: updatedAbsences));
  }

  Future<void> _updateEmployee(WidgetRef ref, Employee updatedEmployee) async {
    await ref.read(employeeRepositoryProvider).update(updatedEmployee);
  }
}

class _NotesTab extends StatelessWidget {
  final Employee employee;
  const _NotesTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notizen', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            employee.notes ?? 'Keine Notizen',
            style: TextStyle(color: employee.notes == null ? SeebadColors.textSecondary : null),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: SeebadColors.textSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _EmployeeFormDialog extends ConsumerStatefulWidget {
  final Employee? employee;

  const _EmployeeFormDialog({this.employee});

  @override
  ConsumerState<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late int _workloadPct;
  late ContractStatus _contractStatus;
  late List<String> _areas;
  late TimeRestrictions _timeRestrictions;
  late SoftPreference _softPreference;
  late List<DateRange> _vacations;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.employee?.firstName);
    _lastNameController = TextEditingController(text: widget.employee?.lastName);
    _workloadPct = widget.employee?.workloadPct ?? 100;
    _contractStatus = widget.employee?.contractStatus ?? ContractStatus.fixangestellt;
    _areas = List.from(widget.employee?.areas ?? []);
    _timeRestrictions = widget.employee?.timeRestrictions ?? TimeRestrictions.empty();
    _softPreference = widget.employee?.softPreference ?? SoftPreference.egal;
    _vacations = List.from(widget.employee?.absences.vacationRanges ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.employee == null ? 'Neuer Mitarbeiter' : 'Mitarbeiter bearbeiten'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: SeebadColors.primary,
                unselectedLabelColor: SeebadColors.textSecondary,
                tabs: [
                  Tab(text: 'Stammdaten'),
                  Tab(text: 'Abwesenheiten'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGeneralTab(),
                    _buildAbsencesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Speichern'),
        ),
      ],
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Vorname'),
                    validator: (v) => v?.isEmpty ?? true ? 'Pflichtfeld' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Nachname'),
                    validator: (v) => v?.isEmpty ?? true ? 'Pflichtfeld' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ContractStatus>(
              value: _contractStatus,
              decoration: const InputDecoration(labelText: 'Vertragsstatus'),
              items: ContractStatus.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.label),
              )).toList(),
              onChanged: (v) => setState(() => _contractStatus = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arbeitsumfang: $_workloadPct%'),
                      Slider(
                        value: _workloadPct.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        onChanged: (v) => setState(() => _workloadPct = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Bereiche', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Sauna'),
                  selected: _areas.contains(ShiftArea.sauna),
                  onSelected: (v) => setState(() {
                    if (v) _areas.add(ShiftArea.sauna);
                    else _areas.remove(ShiftArea.sauna);
                  }),
                ),
                FilterChip(
                  label: const Text('Mili'),
                  selected: _areas.contains(ShiftArea.mili),
                  onSelected: (v) => setState(() {
                    if (v) _areas.add(ShiftArea.mili);
                    else _areas.remove(ShiftArea.mili);
                  }),
                ),
                FilterChip(
                  label: const Text('Hallenbad/Strandbad'),
                  selected: _areas.contains(ShiftArea.hallenbadStrandbad),
                  onSelected: (v) => setState(() {
                    if (v) _areas.add(ShiftArea.hallenbadStrandbad);
                    else _areas.remove(ShiftArea.hallenbadStrandbad);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            DropdownButtonFormField<TimeRestriction>(
              value: _timeRestrictions.global,
              decoration: const InputDecoration(labelText: 'Zeitliche Einschränkung'),
              items: TimeRestriction.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.label ?? 'Keine'),
              )).toList(),
              onChanged: (v) => setState(() => _timeRestrictions = _timeRestrictions.copyWith(global: v!)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SoftPreference>(
              value: _softPreference,
              decoration: const InputDecoration(labelText: 'Präferenz'),
              items: SoftPreference.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.label),
              )).toList(),
              onChanged: (v) => setState(() => _softPreference = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsencesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Geplante Urlaube/Abwesenheiten', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () async {
                final result = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (result != null) {
                  setState(() {
                    _vacations.add(DateRange(from: result.start, to: result.end));
                    _vacations.sort((a, b) => a.from.compareTo(b.from));
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_vacations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Keine Urlaube eingetragen.', style: TextStyle(color: SeebadColors.textSecondary)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _vacations.length,
              itemBuilder: (context, index) {
                final range = _vacations[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.beach_access, color: Colors.orange),
                    title: Text('${_formatDate(range.from)} - ${_formatDate(range.to)}'),
                    subtitle: Text('${range.to.difference(range.from).inDays + 1} Tage'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: SeebadColors.textSecondary),
                      onPressed: () => setState(() => _vacations.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _save() async {
    // If validation fails on general tab, switch to it
    if (!_formKey.currentState!.validate()) {
      DefaultTabController.of(context).animateTo(0);
      return;
    }
    if (_areas.isEmpty) {
      DefaultTabController.of(context).animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens einen Bereich auswählen')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(employeeRepositoryProvider);
      
      final employee = Employee(
        id: widget.employee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        isActive: widget.employee?.isActive ?? true,
        contractStatus: _contractStatus,
        contractWorkPattern: ContractWorkPattern.unbeschraenkt,
        workloadPct: _workloadPct,
        areas: _areas,
        contractStart: widget.employee?.contractStart ?? DateTime.now(),
        contractEnd: widget.employee?.contractEnd,
        softPreference: _softPreference,
        timeRestrictions: _timeRestrictions,
        freeDaysPerWeek: widget.employee?.freeDaysPerWeek ?? FreeDaysPerWeek(count: 2),
        absences: Absences(
          vacationRanges: _vacations,
          shortUnavailability: widget.employee?.absences.shortUnavailability ?? [],
        ),
        notes: widget.employee?.notes,
      );

      if (widget.employee == null) {
        await repo.create(employee);
      } else {
        await repo.update(employee);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.employee == null ? 'Mitarbeiter erstellt' : 'Mitarbeiter aktualisiert')),
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

// Schicht-Einstellungen screen - Shift settings management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'package:collection/collection.dart';

/// Shift settings screen with templates and demand configuration
class SchichtEinstellungenScreen extends ConsumerStatefulWidget {
  const SchichtEinstellungenScreen({super.key});

  @override
  ConsumerState<SchichtEinstellungenScreen> createState() => _SchichtEinstellungenScreenState();
}

class _SchichtEinstellungenScreenState extends ConsumerState<SchichtEinstellungenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: SeebadColors.primary,
            indicatorColor: SeebadColors.primary,
            tabs: const [
              Tab(text: 'Schichtvorlagen'),
              Tab(text: 'Bedarfseinstellungen'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ShiftTemplatesTab(),
              _DemandSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShiftTemplatesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(shiftTemplatesProvider);

    return templates.when(
      data: (list) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: SeebadShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Schichtvorlagen', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: SeebadColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${list.length} Vorlagen', style: const TextStyle(fontSize: 12, color: SeebadColors.info)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showTemplateDialog(context, ref, null),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Neue Vorlage'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Label')),
                  DataColumn(label: Text('Bereich')),
                  DataColumn(label: Text('Standort')),
                  DataColumn(label: Text('Segment')),
                  DataColumn(label: Text('Min/Ideal')),
                  DataColumn(label: Text('Aktiv')),
                  DataColumn(label: Text('Aktionen')),
                ],
                rows: list.map((t) => DataRow(
                  cells: [
                    DataCell(Text(t.code, style: const TextStyle(fontFamily: 'monospace'))),
                    DataCell(Text(t.label, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(_AreaBadge(area: t.area)),
                    DataCell(Text(ShiftSite.labelGerman(t.site) ?? '—')),
                    DataCell(_SegmentBadge(segment: t.daySegment)),
                    DataCell(Text('${t.minStaffDefault}/${t.idealStaffDefault}')),
                    DataCell(Switch(
                      value: t.isActive,
                      onChanged: (v) async {
                        await ref.read(shiftTemplateRepositoryProvider).update(t.copyWith(isActive: v));
                      },
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: SeebadColors.primary),
                          onPressed: () => _showTemplateDialog(context, ref, t),
                          tooltip: 'Bearbeiten',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: SeebadColors.error),
                          onPressed: () => _deleteTemplate(context, ref, t),
                          tooltip: 'Löschen',
                        ),
                      ],
                    )),
                  ],
                )).toList(),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
    );
  }

  Future<void> _showTemplateDialog(BuildContext context, WidgetRef ref, ShiftTemplate? template) async {
    await showDialog(
      context: context,
      builder: (context) => _ShiftTemplateDialog(template: template),
    );
  }

  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref, ShiftTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vorlage löschen?'),
        content: Text('Soll die Vorlage "${template.label}" wirklich gelöscht werden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SeebadColors.error),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(shiftTemplateRepositoryProvider).delete(template.code);
    }
  }
}

class _ShiftTemplateDialog extends ConsumerStatefulWidget {
  final ShiftTemplate? template;
  const _ShiftTemplateDialog({this.template});

  @override
  ConsumerState<_ShiftTemplateDialog> createState() => _ShiftTemplateDialogState();
}

class _ShiftTemplateDialogState extends ConsumerState<_ShiftTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _labelController;
  late String _area;
  late String _site;
  late DaySegment _segment;
  late int _minStaff;
  late int _idealStaff;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.template?.code ?? '');
    _labelController = TextEditingController(text: widget.template?.label ?? '');
    _area = widget.template?.area ?? ShiftArea.hallenbadStrandbad;
    _site = widget.template?.site ?? ShiftSite.hallenbad;
    _segment = widget.template?.daySegment ?? DaySegment.am;
    _minStaff = widget.template?.minStaffDefault ?? 1;
    _idealStaff = widget.template?.idealStaffDefault ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.template == null;
    return AlertDialog(
      title: Text(isNew ? 'Neue Schichtvorlage' : 'Vorlage bearbeiten'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code (Unique ID)',
                    helperText: 'z.B. KASSA_AM (Großbuchstaben)',
                  ),
                  enabled: isNew, // Code cannot be changed
                  validator: (v) => v?.isEmpty ?? true ? 'Pflichtfeld' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(labelText: 'Bezeichnung'),
                  validator: (v) => v?.isEmpty ?? true ? 'Pflichtfeld' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _area,
                  decoration: const InputDecoration(labelText: 'Bereich'),
                  items: [
                    ShiftArea.hallenbadStrandbad,
                    ShiftArea.sauna,
                    ShiftArea.mili,
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _area = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _site,
                  decoration: const InputDecoration(labelText: 'Standort'),
                  items: ShiftSite.all.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(ShiftSite.labelGerman(s) ?? s),
                  )).toList(),
                  onChanged: (v) => setState(() => _site = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DaySegment>(
                  value: _segment,
                  decoration: const InputDecoration(labelText: 'Tageszeit'),
                  items: DaySegment.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.labelGerman),
                  )).toList(),
                  onChanged: (v) => setState(() => _segment = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _minStaff.toString(),
                        decoration: const InputDecoration(labelText: 'Min. Personal'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _minStaff = int.tryParse(v) ?? 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _idealStaff.toString(),
                        decoration: const InputDecoration(labelText: 'Ideal Personal'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _idealStaff = int.tryParse(v) ?? 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(shiftTemplateRepositoryProvider);
      final template = ShiftTemplate(
        code: _codeController.text.toUpperCase().trim(),
        label: _labelController.text.trim(),
        area: _area,
        site: _site,
        daySegment: _segment,
        minStaffDefault: _minStaff,
        idealStaffDefault: _idealStaff,
        isActive: true,
      );

      if (widget.template == null) {
        await repo.create(template);
      } else {
        await repo.update(template);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _AreaBadge extends StatelessWidget {
  final String area;

  const _AreaBadge({required this.area});

  @override
  Widget build(BuildContext context) {
    Color color = SeebadColors.areaBad;
    if (area.contains('Sauna')) color = SeebadColors.areaSauna;
    if (area.contains('Mili')) color = SeebadColors.areaMili;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        area.length > 15 ? '${area.substring(0, 12)}...' : area,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SegmentBadge extends StatelessWidget {
  final DaySegment segment;

  const _SegmentBadge({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SeebadColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(segment.labelGerman, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _DemandSettingsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DemandSettingsTab> createState() => _DemandSettingsTabState();
}

class _DemandSettingsTabState extends ConsumerState<_DemandSettingsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subtabController;

  @override
  void initState() {
    super.initState();
    _subtabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subtabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: SeebadColors.surfaceVariant,
          child: TabBar(
            controller: _subtabController,
            labelColor: SeebadColors.primary,
            indicatorColor: SeebadColors.primary,
            tabs: const [
              Tab(text: 'Grundeinstellungen'),
              Tab(text: 'Wochentagmuster'),
              Tab(text: 'Periodenüberschreibungen'),
            ],
          ),
        ),
        // Info box
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SeebadColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SeebadColors.info.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: SeebadColors.info, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auflösungspriorität: Datumsüberschreibung > Wochentagmuster > Grundeinstellung > Vorlagen-Standard',
                  style: TextStyle(color: SeebadColors.info, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subtabController,
            children: [
              _BaselineSettings(),
              _WeekdayPatterns(),
              _PeriodOverrides(),
            ],
          ),
        ),
      ],
    );
  }
}

class _BaselineSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(shiftTemplatesProvider).valueOrNull ?? [];
    final baseline = ref.watch(baselineDemandProvider).valueOrNull ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: SeebadShadows.card,
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Schicht')),
            DataColumn(label: Text('Min (Override)')),
            DataColumn(label: Text('Ideal (Override)')),
            DataColumn(label: Text('Max (Override)')),
            DataColumn(label: Text('Aktiv (Override)')),
            DataColumn(label: Text('Aktionen')),
          ],
          rows: templates.map((t) {
            final override = baseline[t.code];
            return DataRow(cells: [
              DataCell(Text(t.label)),
              DataCell(Text(override?.min?.toString() ?? '—')),
              DataCell(Text(override?.ideal?.toString() ?? '—')),
              DataCell(Text(override?.max?.toString() ?? '—')),
              DataCell(Text(override?.isActive?.toString() ?? '—')),
              DataCell(IconButton(
                icon: const Icon(Icons.edit, size: 18, color: SeebadColors.primary),
                onPressed: () => _showDemandDialog(context, ref, t, override, (newOverride) async {
                  await ref.read(settingsRepositoryProvider).saveBaselineDemand(newOverride);
                }),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  }
Future<void> _showDemandDialog(
  BuildContext context,
  WidgetRef ref,
  ShiftTemplate template,
  DemandOverride? existing,
  Future<void> Function(DemandOverride) onSave,
) async {
  await showDialog(
    context: context,
    builder: (context) => _DemandOverrideDialog(
      template: template,
      override: existing,
      onSave: onSave,
    ),
  );
}

class _DemandOverrideDialog extends StatefulWidget {
  final ShiftTemplate template;
  final DemandOverride? override;
  final Future<void> Function(DemandOverride) onSave;

  const _DemandOverrideDialog({
    required this.template,
    this.override,
    required this.onSave,
  });

  @override
  State<_DemandOverrideDialog> createState() => _DemandOverrideDialogState();
}

class _DemandOverrideDialogState extends State<_DemandOverrideDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _min;
  late int? _ideal;
  late int? _max;
  late bool? _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _min = widget.override?.min;
    _ideal = widget.override?.ideal;
    _max = widget.override?.max;
    _isActive = widget.override?.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bedarf: ${widget.template.label}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Werte leer lassen, um Standard der Vorlage zu nutzen.', 
                style: TextStyle(fontSize: 12, color: SeebadColors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _min?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Min Override'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _min = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _ideal?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Ideal Override'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _ideal = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _max?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Max Override'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _max = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      value: _isActive,
                      decoration: const InputDecoration(labelText: 'Aktiv Override'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Standard')),
                        DropdownMenuItem(value: true, child: Text('Ja')),
                        DropdownMenuItem(value: false, child: Text('Nein')),
                      ],
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Speichern'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final override = DemandOverride(
        templateCode: widget.template.code,
        min: _min,
        ideal: _ideal,
        max: _max,
        isActive: _isActive,
      );
      await widget.onSave(override);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

class _WeekdayPatterns extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekdaysDe = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    final weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final templatesAsync = ref.watch(activeShiftTemplatesProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekdaysDe.length,
      itemBuilder: (context, index) {
        final weekdayDisplay = weekdaysDe[index];
        final weekdayKey = weekdaysEn[index];
        final patternsAsync = ref.watch(weekdayPatternsProvider(weekdayKey));

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: SeebadShadows.card,
          ),
          child: ExpansionTile(
            title: Text(weekdayDisplay),
            leading: Icon(
              index >= 5 ? Icons.weekend : Icons.work,
              color: index >= 5 ? SeebadColors.primary : SeebadColors.textSecondary,
            ),
            children: [
              patternsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Fehler: $e')),
                data: (patterns) => Column(
                  children: [
                    if (patterns.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Keine speziellen Anforderungen.', style: TextStyle(color: SeebadColors.textSecondary)),
                      )
                    else
                      ...patterns.values.map((override) {
                        return templatesAsync.when(
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                          data: (templates) {
                            final t = templates.firstWhereOrNull((t) => t.code == override.templateCode);
                            if (t == null) return const SizedBox.shrink();
                            return ListTile(
                              title: Text(t.label),
                              subtitle: Text('Min: ${override.min ?? "-"}, Ideal: ${override.ideal ?? "-"}, Max: ${override.max ?? "-"}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _showDemandDialog(context, ref, t, override, (newOverride) async {
                                      await ref.read(settingsRepositoryProvider).saveWeekdayPattern(weekdayKey, newOverride);
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: SeebadColors.error),
                                    onPressed: () async {
                                      // TODO: Add confirmation dialog
                                      await ref.read(settingsRepositoryProvider).deleteWeekdayPattern(weekdayKey, override.templateCode);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton.icon(
                        onPressed: () => _addOverride(context, ref, weekdayKey),
                        icon: const Icon(Icons.add),
                        label: const Text('Anforderung hinzufügen'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addOverride(BuildContext context, WidgetRef ref, String weekdayKey) async {
    final templates = await ref.read(activeShiftTemplatesProvider.future);
    
    // Show dialog to select template
    if (context.mounted) {
      final ShiftTemplate? selected = await showDialog<ShiftTemplate>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Schicht wählen'),
          children: templates.map((t) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, t),
            child: Text(t.label),
          )).toList(),
        ),
      );

      if (selected != null && context.mounted) {
        // Show demand dialog for new override
        await _showDemandDialog(context, ref, selected, null, (override) async {
          await ref.read(settingsRepositoryProvider).saveWeekdayPattern(weekdayKey, override);
        });
      }
    }
  }
}

class _PeriodOverrides extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(periodsProvider).valueOrNull ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Periode wählen'),
            items: periods.map((p) => DropdownMenuItem(value: p.id, child: Text(p.displayLabel))).toList(),
            onChanged: (v) {},
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: SeebadShadows.card,
            ),
            child: Column(
              children: [
                const Icon(Icons.event_note, size: 48, color: SeebadColors.textSecondary),
                const SizedBox(height: 16),
                Text('Wähle eine Periode', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Dann kannst du datumsspezifische Überschreibungen hinzufügen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SeebadColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

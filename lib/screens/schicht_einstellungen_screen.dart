// Schicht-Einstellungen screen - Shift settings management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

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
          ],
          rows: templates.map((t) {
            final override = baseline[t.code];
            return DataRow(cells: [
              DataCell(Text(t.label)),
              DataCell(Text(override?.min?.toString() ?? '—')),
              DataCell(Text(override?.ideal?.toString() ?? '—')),
              DataCell(Text(override?.max?.toString() ?? '—')),
              DataCell(Text(override?.isActive?.toString() ?? '—')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _WeekdayPatterns extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekdays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekdays.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: SeebadShadows.card,
        ),
        child: ExpansionTile(
          title: Text(weekdays[index]),
          leading: Icon(
            index >= 5 ? Icons.weekend : Icons.work,
            color: index >= 5 ? SeebadColors.primary : SeebadColors.textSecondary,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Keine Überschreibungen für ${weekdays[index]}',
                style: const TextStyle(color: SeebadColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
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

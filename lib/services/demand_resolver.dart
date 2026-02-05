// Demand resolution service
// Resolves effective demand for each date and shift template

import '../models/models.dart';

/// Resolves demand based on priority: Date Override > Weekday Pattern > Baseline > Default
class DemandResolver {
  final Map<String, DemandOverride> baseline;
  final Map<String, Map<String, DemandOverride>> weekdayPatterns;
  final Map<String, DateDemandOverride> dateOverrides;
  final List<ShiftTemplate> templates;

  DemandResolver({
    required this.baseline,
    required this.weekdayPatterns,
    required this.dateOverrides,
    required this.templates,
  });

  /// Resolve effective demand for a specific date and shift template
  ResolvedDemand resolve(DateTime date, ShiftTemplate template) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}#${template.code}';
    
    // Priority 1: Date-specific override
    final dateOvr = dateOverrides[dateKey];
    if (dateOvr != null) {
      return ResolvedDemand(
        templateCode: template.code,
        date: date,
        min: dateOvr.min ?? template.minStaffDefault,
        ideal: dateOvr.ideal ?? template.idealStaffDefault,
        max: dateOvr.max ?? template.idealStaffDefault,
        isActive: dateOvr.isActive ?? template.isActive,
        source: 'date_override',
      );
    }

    // Priority 2: Weekday pattern
    final weekdayName = _weekdayName(date.weekday);
    final weekdayPattern = weekdayPatterns[weekdayName]?[template.code];
    if (weekdayPattern != null) {
      return ResolvedDemand(
        templateCode: template.code,
        date: date,
        min: weekdayPattern.min ?? template.minStaffDefault,
        ideal: weekdayPattern.ideal ?? template.idealStaffDefault,
        max: weekdayPattern.max ?? template.idealStaffDefault,
        isActive: weekdayPattern.isActive ?? template.isActive,
        source: 'weekday_pattern',
      );
    }

    // Priority 3: Baseline override
    final baselineOvr = baseline[template.code];
    if (baselineOvr != null) {
      return ResolvedDemand(
        templateCode: template.code,
        date: date,
        min: baselineOvr.min ?? template.minStaffDefault,
        ideal: baselineOvr.ideal ?? template.idealStaffDefault,
        max: baselineOvr.max ?? template.idealStaffDefault,
        isActive: baselineOvr.isActive ?? template.isActive,
        source: 'baseline',
      );
    }

    // Priority 4: Template defaults
    return ResolvedDemand(
      templateCode: template.code,
      date: date,
      min: template.minStaffDefault,
      ideal: template.idealStaffDefault,
      max: template.idealStaffDefault,
      isActive: template.isActive,
      source: 'template_default',
    );
  }

  /// Resolve demand for all dates and templates in a period
  Map<String, ResolvedDemand> resolveAll(List<DateTime> dates) {
    final result = <String, ResolvedDemand>{};
    for (final date in dates) {
      for (final template in templates.where((t) => t.isActive)) {
        final resolved = resolve(date, template);
        if (resolved.isActive && resolved.shouldGenerateSlots) {
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}#${template.code}';
          result[key] = resolved;
        }
      }
    }
    return result;
  }

  String _weekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }
}

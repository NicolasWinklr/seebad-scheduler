// Solver service
// Main scheduling algorithm with constraint-based greedy assignment

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import '../models/models.dart';
import 'demand_resolver.dart';

/// Represents a slot to be filled (date + template + slot index)
class Slot {
  final DateTime date;
  final String templateCode;
  final int slotIndex;
  final int minSlots;
  final int idealSlots;

  Slot({
    required this.date,
    required this.templateCode,
    required this.slotIndex,
    required this.minSlots,
    required this.idealSlots,
  });

  String get key => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}#$templateCode#$slotIndex';

  bool get isMinimumSlot => slotIndex < minSlots;
  bool get isIdealSlot => slotIndex < idealSlots;
}

/// Result of solving a period
class SolverResult {
  final List<Assignment> assignments;
  final List<SolverViolation> violations;
  final SolverStats stats;

  SolverResult({
    required this.assignments,
    required this.violations,
    required this.stats,
  });
}

/// Solver statistics
class SolverStats {
  final int totalSlots;
  final int filledSlots;
  final int emptyMinSlots;
  final int hardViolations;
  final int softViolations;

  SolverStats({
    required this.totalSlots,
    required this.filledSlots,
    required this.emptyMinSlots,
    required this.hardViolations,
    required this.softViolations,
  });

  double get coveragePercent => totalSlots > 0 ? (filledSlots / totalSlots) * 100 : 0;
}

/// A violation found by the solver
class SolverViolation {
  final DateTime date;
  final String templateCode;
  final int? slotIndex;
  final String? employeeId;
  final ViolationCode code;
  final String explanation;

  SolverViolation({
    required this.date,
    required this.templateCode,
    this.slotIndex,
    this.employeeId,
    required this.code,
    required this.explanation,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'templateCode': templateCode,
      'slotIndex': slotIndex,
      'employeeId': employeeId,
      'code': code.toString().split('.').last,
      'explanation': explanation,
    };
  }

  factory SolverViolation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SolverViolation(
      date: (data['date'] as Timestamp).toDate(),
      templateCode: data['templateCode'] ?? '',
      slotIndex: data['slotIndex'],
      employeeId: data['employeeId'],
      code: ViolationCode.values.firstWhere(
        (e) => e.toString().split('.').last == data['code'],
        orElse: () => ViolationCode.other,
      ),
      explanation: data['explanation'] ?? '',
    );
  }
}

/// Main solver class
class Solver {
  final List<Employee> employees;
  final List<ShiftTemplate> templates;
  final SolverConfig config;
  final DemandResolver demandResolver;
  final List<AssignmentLock> locks;
  final List<Assignment> existingAssignments;

  // Tracking state during solving
  final Map<String, int> _employeeHours = {};
  final Map<String, int> _employeeSundays = {};
  final Map<String, Set<String>> _employeeShiftsByDate = {};

  Solver({
    required this.employees,
    required this.templates,
    required this.config,
    required this.demandResolver,
    required this.locks,
    this.existingAssignments = const [],
  });

  /// Run the solver for a period
  SolverResult solve(Period period) {
    final dates = period.allDates;
    final assignments = <Assignment>[];
    final violations = <SolverViolation>[];

    // Initialize tracking
    _initializeTracking();

    // Phase 1: Generate slots based on demand
    final resolvedDemand = demandResolver.resolveAll(dates);
    final slots = _generateSlots(resolvedDemand);

    // Phase 2: Process locked cells first
    _processLocks(slots, assignments, period.id);

    // Phase 3: Assign employees to remaining slots using greedy algorithm
    for (final slot in slots.where((s) => !_isSlotFilled(s, assignments))) {
      final assignment = _assignBestEmployee(slot, assignments, dates, period.id);
      if (assignment != null) {
        assignments.add(assignment);
        _updateTracking(assignment);
      }
    }

    // Phase 4: Calculate violations
    violations.addAll(_calculateViolations(assignments, resolvedDemand, dates));

    // Calculate stats
    final stats = SolverStats(
      totalSlots: slots.length,
      filledSlots: assignments.length,
      emptyMinSlots: slots.where((s) => s.isMinimumSlot && !_isSlotFilled(s, assignments)).length,
      hardViolations: violations.where((v) => v.code.isHard).length,
      softViolations: violations.where((v) => !v.code.isHard).length,
    );

    return SolverResult(
      assignments: assignments,
      violations: violations,
      stats: stats,
    );
  }

  void _initializeTracking() {
    _employeeHours.clear();
    _employeeSundays.clear();
    _employeeShiftsByDate.clear();

    for (final emp in employees) {
      _employeeHours[emp.id] = 0;
      _employeeSundays[emp.id] = 0;
    }
  }

  List<Slot> _generateSlots(Map<String, ResolvedDemand> demand) {
    final slots = <Slot>[];
    for (final entry in demand.entries) {
      final resolved = entry.value;
      final maxSlots = resolved.max;
      for (int i = 0; i < maxSlots; i++) {
        slots.add(Slot(
          date: resolved.date,
          templateCode: resolved.templateCode,
          slotIndex: i,
          minSlots: resolved.min,
          idealSlots: resolved.ideal,
        ));
      }
    }
    // Sort slots by priority: min slots first, then by date
    slots.sort((a, b) {
      if (a.isMinimumSlot != b.isMinimumSlot) {
        return a.isMinimumSlot ? -1 : 1;
      }
      return a.date.compareTo(b.date);
    });
    return slots;
  }

  void _processLocks(List<Slot> slots, List<Assignment> assignments, String periodId) {
    for (final lock in locks) {
      final slot = slots.firstWhereOrNull((s) =>
        s.date == lock.date &&
        s.templateCode == lock.shiftTemplateCode &&
        (lock.slotIndex == null || s.slotIndex == lock.slotIndex)
      );
      if (slot == null) continue;

      final template = templates.firstWhereOrNull((t) => t.code == lock.shiftTemplateCode);
      if (template == null) continue;

      // Create a locked assignment (no employee assigned unless we have a prior assignment)
      final assignment = Assignment(
        id: '${lock.date.year}-${lock.date.month.toString().padLeft(2, '0')}-${lock.date.day.toString().padLeft(2, '0')}#${lock.shiftTemplateCode}#${lock.slotIndex ?? 0}',
        periodId: periodId,
        date: lock.date,
        shiftTemplateCode: lock.shiftTemplateCode,
        area: template.area,
        site: template.site,
        slotIndex: lock.slotIndex ?? 0,
        status: AssignmentStatus.locked,
        source: AssignmentSource.manual,
        violationCodes: [],
      );
      assignments.add(assignment);
    }
  }

  bool _isSlotFilled(Slot slot, List<Assignment> assignments) {
    return assignments.any((a) =>
      a.date == slot.date &&
      a.shiftTemplateCode == slot.templateCode &&
      a.slotIndex == slot.slotIndex
    );
  }

  Assignment? _assignBestEmployee(Slot slot, List<Assignment> assignments, List<DateTime> periodDates, String periodId) {
    final template = templates.firstWhereOrNull((t) => t.code == slot.templateCode);
    if (template == null) return null;

    // Get eligible employees
    final eligible = employees.where((emp) => _isEligible(emp, slot, template, assignments, periodDates)).toList();
    if (eligible.isEmpty) return null;

    // Score each employee
    final scored = eligible.map((emp) {
      final score = _scoreEmployee(emp, slot, template, periodDates);
      return (employee: emp, score: score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));

    final best = scored.first;
    return Assignment(
      id: slot.key,
      periodId: periodId,
      date: slot.date,
      shiftTemplateCode: slot.templateCode,
      area: template.area,
      site: template.site,
      slotIndex: slot.slotIndex,
      employeeId: best.employee.id,
      status: AssignmentStatus.proposed,
      source: AssignmentSource.auto,
      violationCodes: [],
    );
  }

  bool _isEligible(Employee emp, Slot slot, ShiftTemplate template, List<Assignment> assignments, List<DateTime> periodDates) {
    // Check if employee is active
    if (!emp.isActive) return false;

    // Check contract dates
    if (slot.date.isBefore(emp.contractStart)) return false;
    if (emp.contractEnd != null && slot.date.isAfter(emp.contractEnd!)) return false;

    // Check area permission
    if (!emp.canWorkInArea(template.area)) return false;

    // Check contract work pattern
    if (!emp.canWorkOnWeekday(slot.date.weekday)) return false;

    // Check already assigned this day
    final dateKey = '${slot.date.year}-${slot.date.month}-${slot.date.day}';
    final shiftsToday = _employeeShiftsByDate['${emp.id}#$dateKey'] ?? {};
    if (shiftsToday.length >= config.maxShiftsPerDayPerEmployee) return false;

    // Check absences (vacation and short unavailability)
    if (emp.absences.isUnavailable(slot.date)) return false;

    // Check late-to-early constraint
    if (config.forbidLateToEarly && _violatesLateToEarly(emp, slot, template)) return false;

    // Check time restrictions
    if (!_passesTimeRestriction(emp, template)) return false;

    return true;
  }

  bool _violatesLateToEarly(Employee emp, Slot slot, ShiftTemplate template) {
    if (template.daySegment != DaySegment.am) return false;

    final previousDay = slot.date.subtract(const Duration(days: 1));
    final prevKey = '${emp.id}#${previousDay.year}-${previousDay.month}-${previousDay.day}';
    final prevShifts = _employeeShiftsByDate[prevKey] ?? {};

    for (final templateCode in prevShifts) {
      final prevTemplate = templates.firstWhereOrNull((t) => t.code == templateCode);
      if (prevTemplate != null && prevTemplate.daySegment == DaySegment.pm) {
        return true;
      }
    }
    return false;
  }

  bool _passesTimeRestriction(Employee emp, ShiftTemplate template) {
    final restriction = emp.timeRestrictions.global;
    switch (restriction) {
      case TimeRestriction.unrestricted:
        return true;
      case TimeRestriction.nurVormittags:
        return template.daySegment == DaySegment.am;
      case TimeRestriction.nurNachmittags:
        return template.daySegment == DaySegment.pm;
    }
  }

  double _scoreEmployee(Employee emp, Slot slot, ShiftTemplate template, List<DateTime> periodDates) {
    double score = 100.0;

    // Factor 1: Fill ratio (prefer under-utilized employees)
    final currentHours = _employeeHours[emp.id] ?? 0;
    final targetHours = _calculateTargetHours(emp, periodDates.length);
    
    if (targetHours > 0) {
      // 0.0 = 0% filled, 1.0 = 100% filled
      final ratio = currentHours / targetHours;
      // Bonus for being under target (ratio < 1.0), Penalty for being over (ratio > 1.0)
      // E.g. at 0% -> +50 score. At 50% -> +25 score. At 100% -> 0. At 120% -> -10.
      score += (1.0 - ratio) * 50; 
    } else {
      // Penalty per hour if target is 0
      score -= currentHours * 5;
    }

    // Factor 2: Sunday fairness
    if (slot.date.weekday == 7) {
      final currentSundays = _employeeSundays[emp.id] ?? 0;
      if (currentSundays >= config.sundayTargetMax) {
        score -= 50;
      } else if (currentSundays < config.sundayTargetMin) {
        score += 30;
      }
    }

    // Factor 3: Soft preferences
    switch (emp.softPreference) {
      case SoftPreference.egal:
        break;
      case SoftPreference.lieberUnterDerWoche:
        if (slot.date.weekday >= 6) score -= (config.weightSoftPreference / 2);
        break;
      case SoftPreference.keinWochenende:
        if (slot.date.weekday >= 6) score -= config.weightSoftPreference;
        break;
    }

    // Factor 4: Block planning (prefer consecutive days)
    final previousDay = slot.date.subtract(const Duration(days: 1));
    final prevKey = '${emp.id}#${previousDay.year}-${previousDay.month}-${previousDay.day}';
    if ((_employeeShiftsByDate[prevKey] ?? {}).isNotEmpty) {
      score += (config.weightBlockPlanning / 5);
    }

    return score;
  }

  int _calculateTargetHours(Employee emp, int periodDays) {
    // Simple target: workload percentage * period days * average hours per day
    const avgShiftHours = 6;
    final workDays = (periodDays * emp.workloadPct / 100 * 5 / 7).round();
    return workDays * avgShiftHours;
  }

  void _updateTracking(Assignment assignment) {
    final template = templates.firstWhereOrNull((t) => t.code == assignment.shiftTemplateCode);
    if (template == null || assignment.employeeId == null) return;

    // Update hours (estimate based on day segment)
    final hours = _employeeHours[assignment.employeeId] ?? 0;
    final shiftHours = template.daySegment == DaySegment.allday ? 8 : 6;
    _employeeHours[assignment.employeeId!] = hours + shiftHours;

    // Update sundays
    if (assignment.date.weekday == 7) {
      final sundays = _employeeSundays[assignment.employeeId] ?? 0;
      _employeeSundays[assignment.employeeId!] = sundays + 1;
    }

    // Update shifts by date
    final dateKey = '${assignment.employeeId}#${assignment.date.year}-${assignment.date.month}-${assignment.date.day}';
    _employeeShiftsByDate[dateKey] ??= {};
    _employeeShiftsByDate[dateKey]!.add(assignment.shiftTemplateCode);
  }

  List<SolverViolation> _calculateViolations(
    List<Assignment> assignments,
    Map<String, ResolvedDemand> demand,
    List<DateTime> dates,
  ) {
    final violations = <SolverViolation>[];

    // Check coverage violations
    for (final entry in demand.entries) {
      final resolved = entry.value;
      final assignedCount = assignments.where((a) =>
        a.date == resolved.date && a.shiftTemplateCode == resolved.templateCode
      ).length;

      if (assignedCount < resolved.min) {
        violations.add(SolverViolation(
          date: resolved.date,
          templateCode: resolved.templateCode,
          code: ViolationCode.underMinCoverage,
          explanation: 'Nur $assignedCount von ${resolved.min} Mindestplätzen besetzt',
        ));
      }
    }

    // Check employee-specific violations
    for (final emp in employees.where((e) => e.isActive)) {
      // Check hours deviation
      final totalHours = _employeeHours[emp.id] ?? 0;
      final targetHours = _calculateTargetHours(emp, dates.length);
      final deviation = (totalHours - targetHours).abs();
      if (deviation > targetHours * 0.2) {
        violations.add(SolverViolation(
          date: dates.first,
          templateCode: '',
          employeeId: emp.id,
          code: ViolationCode.hoursDeviation,
          explanation: '${emp.fullName}: $totalHours Std. geplant (Vertragsziel: $targetHours Std.) - bitte prüfen',
        ));
      }

      // Check Sunday fairness
      final sundays = _employeeSundays[emp.id] ?? 0;
      if (sundays < config.sundayTargetMin && sundays > 0) {
        violations.add(SolverViolation(
          date: dates.first,
          templateCode: '',
          employeeId: emp.id,
          code: ViolationCode.sundayFairness,
          explanation: '${emp.fullName}: Nur $sundays Sonntagsschichten (Mindestens ${config.sundayTargetMin} erwartet)',
        ));
      } else if (sundays > config.sundayTargetMax) {
        violations.add(SolverViolation(
          date: dates.first,
          templateCode: '',
          employeeId: emp.id,
          code: ViolationCode.sundayFairness,
          explanation: '${emp.fullName}: $sundays Sonntagsschichten (Maximal ${config.sundayTargetMax} erlaubt)',
        ));
      }
    }

    return violations;
  }
}

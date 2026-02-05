// Assignment model for shift assignments
// Matches Firestore 'periods/{periodId}/assignments' subcollection schema

import 'package:cloud_firestore/cloud_firestore.dart';

/// Assignment source (how it was created)
enum AssignmentSource {
  auto('AUTO'),
  manual('MANUAL');

  final String value;
  const AssignmentSource(this.value);

  static AssignmentSource fromString(String value) {
    return AssignmentSource.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase() || e.value == value,
      orElse: () => AssignmentSource.auto,
    );
  }
}

/// Assignment status
enum AssignmentStatus {
  proposed('PROPOSED', 'Vorgeschlagen'),
  confirmed('CONFIRMED', 'Bestätigt'),
  locked('LOCKED', 'Gesperrt');

  final String value;
  final String labelGerman;
  const AssignmentStatus(this.value, this.labelGerman);

  static AssignmentStatus fromString(String value) {
    return AssignmentStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase() || e.value == value,
      orElse: () => AssignmentStatus.proposed,
    );
  }
}

/// Violation codes for constraint violations
enum ViolationCode {
  // Hard violations
  underMinCoverage('UNDER_MIN_COVERAGE', 'Zu wenig Personal', true),
  noEligibleStaff('NO_ELIGIBLE_STAFF', 'Kein verfügbares Personal', true),
  lateToEarly('LATE_TO_EARLY', 'Spätschicht zu Frühschicht', true),
  areaMismatch('AREA_MISMATCH', 'Bereich nicht erlaubt', true),
  contractPatternMismatch('CONTRACT_PATTERN_MISMATCH', 'Vertragsmuster verletzt', true),
  vacationConflict('VACATION_CONFLICT', 'Urlaub', true),
  unavailable('UNAVAILABLE', 'Nicht verfügbar', true),
  fixedFreeDayConflict('FIXED_FREE_DAY_CONFLICT', 'Fixer freier Tag', true),
  freeDaysPerWeekViolation('FREE_DAYS_PER_WEEK_VIOLATION', 'Freie Tage pro Woche verletzt', true),
  timeRestrictionViolation('TIME_RESTRICTION_VIOLATION', 'Zeitbeschränkung verletzt', true),
  maxShiftsPerDayExceeded('MAX_SHIFTS_PER_DAY_EXCEEDED', 'Max. Schichten pro Tag überschritten', true),

  // Soft violations
  softPrefWeekend('SOFT_PREF_WEEKEND', 'Präferenz: Kein Wochenende', false),
  softPrefWeekday('SOFT_PREF_WEEKDAY', 'Präferenz: Lieber unter der Woche', false),
  hoursDeviation('HOURS_DEVIATION', 'Arbeitsstunden-Abweichung', false),
  sundayFairness('SUNDAY_FAIRNESS', 'Sonntag-Fairness', false),
  workloadClustering('WORKLOAD_CLUSTERING', 'Arbeitsbelastung gehäuft', false),
  other('OTHER', 'Sonstiger Konflikt', false);

  final String code;
  final String labelGerman;
  final bool isHard;

  const ViolationCode(this.code, this.labelGerman, this.isHard);

  static ViolationCode? fromString(String value) {
    try {
      return ViolationCode.values.firstWhere(
        (e) => e.code == value || e.name == value,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get color for UI display
  int get color => isHard ? 0xFFE53935 : 0xFFFFB300; // Red for hard, amber for soft
}

/// Shift assignment model
class Assignment {
  final String id;
  final String periodId;
  final DateTime date;
  final String shiftTemplateCode;
  final String area;
  final String? site;
  final int slotIndex;
  final String? employeeId;
  final AssignmentSource source;
  final AssignmentStatus status;
  final List<String> violationCodes;
  final String? notes;
  final String? solverRunId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.periodId,
    required this.date,
    required this.shiftTemplateCode,
    required this.area,
    this.site,
    required this.slotIndex,
    this.employeeId,
    this.source = AssignmentSource.auto,
    this.status = AssignmentStatus.proposed,
    this.violationCodes = const [],
    this.notes,
    this.solverRunId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Check if assignment is filled (has an employee)
  bool get isFilled => employeeId != null;

  /// Check if assignment has violations
  bool get hasViolations => violationCodes.isNotEmpty;

  /// Check if assignment has hard violations
  bool get hasHardViolations {
    return violationCodes.any((code) {
      final violation = ViolationCode.fromString(code);
      return violation?.isHard ?? false;
    });
  }

  /// Check if assignment has only soft violations
  bool get hasOnlySoftViolations => hasViolations && !hasHardViolations;

  /// Get parsed violation codes
  List<ViolationCode> get violations {
    return violationCodes
        .map((code) => ViolationCode.fromString(code))
        .whereType<ViolationCode>()
        .toList();
  }

  /// Factory from Firestore document
  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      periodId: data['periodId'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      shiftTemplateCode: data['shiftTemplateCode'] as String? ?? '',
      area: data['area'] as String? ?? '',
      site: data['site'] as String?,
      slotIndex: data['slotIndex'] as int? ?? 1,
      employeeId: data['employeeId'] as String?,
      source: AssignmentSource.fromString(data['source'] as String? ?? 'AUTO'),
      status: AssignmentStatus.fromString(data['status'] as String? ?? 'PROPOSED'),
      violationCodes: List<String>.from(data['violationCodes'] ?? []),
      notes: data['notes'] as String?,
      solverRunId: data['solverRunId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'periodId': periodId,
      'date': Timestamp.fromDate(date),
      'shiftTemplateCode': shiftTemplateCode,
      'area': area,
      'site': site,
      'slotIndex': slotIndex,
      'employeeId': employeeId,
      'source': source.value,
      'status': status.value,
      'violationCodes': violationCodes,
      'notes': notes,
      'solverRunId': solverRunId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Copy with method
  Assignment copyWith({
    String? id,
    String? periodId,
    DateTime? date,
    String? shiftTemplateCode,
    String? area,
    String? site,
    int? slotIndex,
    String? employeeId,
    AssignmentSource? source,
    AssignmentStatus? status,
    List<String>? violationCodes,
    String? notes,
    String? solverRunId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      date: date ?? this.date,
      shiftTemplateCode: shiftTemplateCode ?? this.shiftTemplateCode,
      area: area ?? this.area,
      site: site ?? this.site,
      slotIndex: slotIndex ?? this.slotIndex,
      employeeId: employeeId ?? this.employeeId,
      source: source ?? this.source,
      status: status ?? this.status,
      violationCodes: violationCodes ?? this.violationCodes,
      notes: notes ?? this.notes,
      solverRunId: solverRunId ?? this.solverRunId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create document ID for Firestore
  static String createDocId(DateTime date, String shiftTemplateCode, int slotIndex) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$dateStr#$shiftTemplateCode#$slotIndex';
  }

  /// Get cell key (date + shift template) for grouping
  String get cellKey {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$dateStr#$shiftTemplateCode';
  }
}

/// Lock model for preventing solver modifications
class AssignmentLock {
  final DateTime date;
  final String shiftTemplateCode;
  final int? slotIndex;
  final DateTime lockedAt;
  final String lockedBy;

  AssignmentLock({
    required this.date,
    required this.shiftTemplateCode,
    this.slotIndex,
    DateTime? lockedAt,
    required this.lockedBy,
  }) : lockedAt = lockedAt ?? DateTime.now();

  /// Check if this lock applies to entire cell
  bool get isCellLock => slotIndex == null;

  /// Factory from Firestore document
  factory AssignmentLock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentLock(
      date: (data['date'] as Timestamp).toDate(),
      shiftTemplateCode: data['shiftTemplateCode'] as String? ?? '',
      slotIndex: data['slotIndex'] as int?,
      lockedAt: (data['lockedAt'] as Timestamp?)?.toDate(),
      lockedBy: data['lockedBy'] as String? ?? '',
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'shiftTemplateCode': shiftTemplateCode,
      'slotIndex': slotIndex,
      'lockedAt': Timestamp.fromDate(lockedAt),
      'lockedBy': lockedBy,
    };
  }

  /// Create document ID for Firestore
  String get docId {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (slotIndex != null) {
      return '$dateStr#$shiftTemplateCode#$slotIndex';
    }
    return '$dateStr#$shiftTemplateCode';
  }
}

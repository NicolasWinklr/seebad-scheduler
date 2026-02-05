// Employee model for staff management
// Matches Firestore 'employees' collection schema

import 'package:cloud_firestore/cloud_firestore.dart';

/// Contract status enum for employees
enum ContractStatus {
  ferialer('Ferialer'),
  fixangestellt('Fixangestellt'),
  teilzeit('Teilzeit');

  final String label;
  const ContractStatus(this.label);

  static ContractStatus fromString(String value) {
    return ContractStatus.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ContractStatus.fixangestellt,
    );
  }
}

/// Contract work pattern - STRICT constraint
enum ContractWorkPattern {
  nurWochenende('nur Wochenende'),
  nurUnterDerWoche('nur unter der Woche'),
  unbeschraenkt('unbeschränkt');

  final String label;
  const ContractWorkPattern(this.label);

  static ContractWorkPattern fromString(String value) {
    return ContractWorkPattern.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ContractWorkPattern.unbeschraenkt,
    );
  }
}

/// Soft preference for scheduling (advisory only)
enum SoftPreference {
  keinWochenende('kein Wochenende'),
  lieberUnterDerWoche('lieber unter der Woche'),
  egal('egal');

  final String label;
  const SoftPreference(this.label);

  static SoftPreference fromString(String value) {
    return SoftPreference.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => SoftPreference.egal,
    );
  }
}

/// Time restriction options
enum TimeRestriction {
  nurVormittags('nur vormittags'),
  nurNachmittags('nur nachmittags'),
  unrestricted(null);

  final String? label;
  const TimeRestriction(this.label);

  static TimeRestriction fromString(String? value) {
    if (value == null) return TimeRestriction.unrestricted;
    return TimeRestriction.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => TimeRestriction.unrestricted,
    );
  }
}

/// Ferialer extra permission for additional shift access
class FerialExtraPermission {
  final String area;
  final String shiftTemplateCode;

  FerialExtraPermission({
    required this.area,
    required this.shiftTemplateCode,
  });

  factory FerialExtraPermission.fromMap(Map<String, dynamic> map) {
    return FerialExtraPermission(
      area: map['area'] as String? ?? '',
      shiftTemplateCode: map['shiftTemplateCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'shiftTemplateCode': shiftTemplateCode,
    };
  }
}

/// Date range for vacation or short unavailability
class DateRange {
  final DateTime from;
  final DateTime to;
  final String? reason;

  DateRange({
    required this.from,
    required this.to,
    this.reason,
  });

  factory DateRange.fromMap(Map<String, dynamic> map) {
    return DateRange(
      from: (map['from'] as Timestamp).toDate(),
      to: (map['to'] as Timestamp).toDate(),
      reason: map['reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': Timestamp.fromDate(from),
      'to': Timestamp.fromDate(to),
      if (reason != null) 'reason': reason,
    };
  }

  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final fromOnly = DateTime(from.year, from.month, from.day);
    final toOnly = DateTime(to.year, to.month, to.day);
    return !dateOnly.isBefore(fromOnly) && !dateOnly.isAfter(toOnly);
  }
}

/// Free days per week configuration
class FreeDaysPerWeek {
  final int count;
  final List<String> fixedWeekdays;

  FreeDaysPerWeek({
    required this.count,
    this.fixedWeekdays = const [],
  });

  factory FreeDaysPerWeek.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return FreeDaysPerWeek(count: 0);
    }
    return FreeDaysPerWeek(
      count: map['count'] as int? ?? 0,
      fixedWeekdays: List<String>.from(map['fixedWeekdays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'fixedWeekdays': fixedWeekdays,
    };
  }
}

/// Time restrictions configuration
class TimeRestrictions {
  final TimeRestriction global;
  final Map<String, TimeRestriction?> perWeekday;
  final Map<String, TimeRestriction> dateOverrides;

  TimeRestrictions({
    this.global = TimeRestriction.unrestricted,
    this.perWeekday = const {},
    this.dateOverrides = const {},
  });

  factory TimeRestrictions.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return TimeRestrictions();
    }

    final perWeekday = <String, TimeRestriction?>{};
    if (map['perWeekday'] != null) {
      (map['perWeekday'] as Map<String, dynamic>).forEach((key, value) {
        perWeekday[key] = TimeRestriction.fromString(value as String?);
      });
    }

    final dateOverrides = <String, TimeRestriction>{};
    if (map['dateOverrides'] != null) {
      (map['dateOverrides'] as Map<String, dynamic>).forEach((key, value) {
        dateOverrides[key] = TimeRestriction.fromString(value as String?);
      });
    }

    return TimeRestrictions(
      global: TimeRestriction.fromString(map['global'] as String?),
      perWeekday: perWeekday,
      dateOverrides: dateOverrides,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'global': global.label,
      'perWeekday': perWeekday.map((k, v) => MapEntry(k, v?.label)),
      'dateOverrides': dateOverrides.map((k, v) => MapEntry(k, v.label)),
    };
  }

  factory TimeRestrictions.empty() => TimeRestrictions();

  /// Copy with method for TimeRestrictions
  TimeRestrictions copyWith({
    TimeRestriction? global,
    Map<String, TimeRestriction?>? perWeekday,
    Map<String, TimeRestriction>? dateOverrides,
  }) {
    return TimeRestrictions(
      global: global ?? this.global,
      perWeekday: perWeekday ?? this.perWeekday,
      dateOverrides: dateOverrides ?? this.dateOverrides,
    );
  }

  /// Get effective time restriction for a specific date
  TimeRestriction getEffectiveRestriction(DateTime date) {
    // Check date override first
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (dateOverrides.containsKey(dateKey)) {
      return dateOverrides[dateKey]!;
    }

    // Check weekday override
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekday = weekdays[date.weekday - 1];
    if (perWeekday.containsKey(weekday) && perWeekday[weekday] != null) {
      return perWeekday[weekday]!;
    }

    // Return global
    return global;
  }
}

/// Absences configuration (vacation + short unavailability)
class Absences {
  final List<DateRange> vacationRanges;
  final List<DateRange> shortUnavailability;

  Absences({
    this.vacationRanges = const [],
    this.shortUnavailability = const [],
  });

  factory Absences.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return Absences();
    }
    return Absences(
      vacationRanges: (map['vacationRanges'] as List<dynamic>?)
              ?.map((e) => DateRange.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      shortUnavailability: (map['shortUnavailability'] as List<dynamic>?)
              ?.map((e) => DateRange.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vacationRanges': vacationRanges.map((e) => e.toMap()).toList(),
      'shortUnavailability': shortUnavailability.map((e) => e.toMap()).toList(),
    };
  }

  /// Copy with method for Absences
  Absences copyWith({
    List<DateRange>? vacationRanges,
    List<DateRange>? shortUnavailability,
  }) {
    return Absences(
      vacationRanges: vacationRanges ?? this.vacationRanges,
      shortUnavailability: shortUnavailability ?? this.shortUnavailability,
    );
  }

  /// Check if employee is unavailable on a specific date
  bool isUnavailable(DateTime date) {
    for (final range in vacationRanges) {
      if (range.containsDate(date)) return true;
    }
    for (final range in shortUnavailability) {
      if (range.containsDate(date)) return true;
    }
    return false;
  }
}

/// Main Employee model
class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final bool isActive;
  final ContractStatus contractStatus;
  final int workloadPct;
  final DateTime contractStart;
  final DateTime? contractEnd;
  final List<String> areas;
  final List<FerialExtraPermission> ferialExtraPermissions;
  final ContractWorkPattern contractWorkPattern;
  final SoftPreference softPreference;
  final String? fixedFreeDay;
  final FreeDaysPerWeek freeDaysPerWeek;
  final TimeRestrictions timeRestrictions;
  final Absences absences;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.isActive = true,
    this.contractStatus = ContractStatus.fixangestellt,
    this.workloadPct = 100,
    required this.contractStart,
    this.contractEnd,
    this.areas = const [],
    this.ferialExtraPermissions = const [],
    this.contractWorkPattern = ContractWorkPattern.unbeschraenkt,
    this.softPreference = SoftPreference.egal,
    this.fixedFreeDay,
    FreeDaysPerWeek? freeDaysPerWeek,
    TimeRestrictions? timeRestrictions,
    Absences? absences,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : freeDaysPerWeek = freeDaysPerWeek ?? FreeDaysPerWeek(count: 0),
        timeRestrictions = timeRestrictions ?? TimeRestrictions(),
        absences = absences ?? Absences(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Full name for display
  String get fullName => '$firstName $lastName';

  /// Factory from Firestore document
  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      contractStatus: ContractStatus.fromString(data['contractStatus'] as String? ?? 'Fixangestellt'),
      workloadPct: data['workloadPct'] as int? ?? 100,
      contractStart: (data['contractStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contractEnd: (data['contractEnd'] as Timestamp?)?.toDate(),
      areas: List<String>.from(data['areas'] ?? []),
      ferialExtraPermissions: (data['ferialExtraPermissions'] as List<dynamic>?)
              ?.map((e) => FerialExtraPermission.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      contractWorkPattern: ContractWorkPattern.fromString(data['contractWorkPattern'] as String? ?? 'unbeschränkt'),
      softPreference: SoftPreference.fromString(data['softPreference'] as String? ?? 'egal'),
      fixedFreeDay: data['fixedFreeDay'] as String?,
      freeDaysPerWeek: FreeDaysPerWeek.fromMap(data['freeDaysPerWeek'] as Map<String, dynamic>?),
      timeRestrictions: TimeRestrictions.fromMap(data['timeRestrictions'] as Map<String, dynamic>?),
      absences: Absences.fromMap(data['absences'] as Map<String, dynamic>?),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'isActive': isActive,
      'contractStatus': contractStatus.name,
      'workloadPct': workloadPct,
      'contractStart': Timestamp.fromDate(contractStart),
      'contractEnd': contractEnd != null ? Timestamp.fromDate(contractEnd!) : null,
      'areas': areas,
      'ferialExtraPermissions': ferialExtraPermissions.map((e) => e.toMap()).toList(),
      'contractWorkPattern': contractWorkPattern.name,
      'softPreference': softPreference.name,
      'fixedFreeDay': fixedFreeDay,
      'freeDaysPerWeek': freeDaysPerWeek.toMap(),
      'timeRestrictions': timeRestrictions.toMap(),
      'absences': absences.toMap(),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Copy with method for immutable updates
  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    bool? isActive,
    ContractStatus? contractStatus,
    int? workloadPct,
    DateTime? contractStart,
    DateTime? contractEnd,
    List<String>? areas,
    List<FerialExtraPermission>? ferialExtraPermissions,
    ContractWorkPattern? contractWorkPattern,
    SoftPreference? softPreference,
    String? fixedFreeDay,
    FreeDaysPerWeek? freeDaysPerWeek,
    TimeRestrictions? timeRestrictions,
    Absences? absences,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      contractStatus: contractStatus ?? this.contractStatus,
      workloadPct: workloadPct ?? this.workloadPct,
      contractStart: contractStart ?? this.contractStart,
      contractEnd: contractEnd ?? this.contractEnd,
      areas: areas ?? this.areas,
      ferialExtraPermissions: ferialExtraPermissions ?? this.ferialExtraPermissions,
      contractWorkPattern: contractWorkPattern ?? this.contractWorkPattern,
      softPreference: softPreference ?? this.softPreference,
      fixedFreeDay: fixedFreeDay ?? this.fixedFreeDay,
      freeDaysPerWeek: freeDaysPerWeek ?? this.freeDaysPerWeek,
      timeRestrictions: timeRestrictions ?? this.timeRestrictions,
      absences: absences ?? this.absences,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if employee can work on given weekday based on contract pattern
  bool canWorkOnWeekday(int weekday) {
    final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;
    switch (contractWorkPattern) {
      case ContractWorkPattern.nurWochenende:
        return isWeekend;
      case ContractWorkPattern.nurUnterDerWoche:
        return !isWeekend;
      case ContractWorkPattern.unbeschraenkt:
        return true;
    }
  }

  /// Check if employee can work the given area
  bool canWorkInArea(String area) {
    return areas.contains(area);
  }

  /// Check if employee has extra permission for shift
  bool hasExtraPermission(String area, String shiftTemplateCode) {
    return ferialExtraPermissions.any(
      (p) => p.area == area && p.shiftTemplateCode == shiftTemplateCode,
    );
  }
}

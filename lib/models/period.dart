// Period model for planning periods (4-week blocks)
// Matches Firestore 'periods' collection schema

import 'package:cloud_firestore/cloud_firestore.dart';

/// Period status enum for lifecycle management
enum PeriodStatus {
  draft('DRAFT', 'Entwurf'),
  optimized('OPTIMIZED', 'Optimiert'),
  review('REVIEW', 'Überprüfung'),
  published('PUBLISHED', 'Veröffentlicht'),
  archived('ARCHIVED', 'Archiviert');

  final String value;
  final String labelGerman;
  const PeriodStatus(this.value, this.labelGerman);

  static PeriodStatus fromString(String value) {
    return PeriodStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase() || e.value == value,
      orElse: () => PeriodStatus.draft,
    );
  }

  /// Get badge color for UI
  int get color {
    switch (this) {
      case PeriodStatus.draft:
        return 0xFF9E9E9E; // Grey
      case PeriodStatus.optimized:
        return 0xFF2196F3; // Blue
      case PeriodStatus.review:
        return 0xFFFF9800; // Orange
      case PeriodStatus.published:
        return 0xFF4CAF50; // Green
      case PeriodStatus.archived:
        return 0xFF795548; // Brown
    }
  }

  /// Check if period can be edited
  bool get isEditable => this != PeriodStatus.archived;

  /// Check if solver can run
  bool get canRunSolver => this == PeriodStatus.draft || this == PeriodStatus.optimized;
}

/// Period model for 4-week planning blocks
class Period {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final PeriodStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int solverRunCount;
  final DateTime? lastSolverRunAt;
  final String? baselineDemandVersion;
  final String? weekdayPatternsVersion;
  final String? solverConfigVersion;

  Period({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.status = PeriodStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.solverRunCount = 0,
    this.lastSolverRunAt,
    this.baselineDemandVersion,
    this.weekdayPatternsVersion,
    this.solverConfigVersion,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a new period for a full calendar month
  factory Period.create({
    required int year,
    required int month,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    final id = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';

    return Period(
      id: id,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Create a periodic block (e.g. 2 weeks) starting on a Monday
  factory Period.createWeeks({
    required DateTime startDate,
    int durationWeeks = 2,
  }) {
    // Round to previous Monday if not already
    final start = startDate.subtract(Duration(days: startDate.weekday - 1));
    final end = start.add(Duration(days: 7 * durationWeeks - 1));
    
    // ID Format: YYYY-MWW (Monday Week)
    final id = '${start.year}-KW${((start.difference(DateTime(start.year, 1, 1)).inDays) / 7).ceil()}';

    return Period(
      id: id,
      startDate: start,
      endDate: end,
    );
  }

  /// Factory from Firestore document
  factory Period.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Period(
      id: doc.id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: PeriodStatus.fromString(data['status'] as String? ?? 'DRAFT'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      solverRunCount: data['solverRunCount'] as int? ?? 0,
      lastSolverRunAt: (data['lastSolverRunAt'] as Timestamp?)?.toDate(),
      baselineDemandVersion: data['baselineDemandVersion'] as String?,
      weekdayPatternsVersion: data['weekdayPatternsVersion'] as String?,
      solverConfigVersion: data['solverConfigVersion'] as String?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'solverRunCount': solverRunCount,
      'lastSolverRunAt': lastSolverRunAt != null ? Timestamp.fromDate(lastSolverRunAt!) : null,
      'baselineDemandVersion': baselineDemandVersion,
      'weekdayPatternsVersion': weekdayPatternsVersion,
      'solverConfigVersion': solverConfigVersion,
    };
  }

  /// Copy with method
  Period copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    PeriodStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? solverRunCount,
    DateTime? lastSolverRunAt,
    String? baselineDemandVersion,
    String? weekdayPatternsVersion,
    String? solverConfigVersion,
  }) {
    return Period(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      solverRunCount: solverRunCount ?? this.solverRunCount,
      lastSolverRunAt: lastSolverRunAt ?? this.lastSolverRunAt,
      baselineDemandVersion: baselineDemandVersion ?? this.baselineDemandVersion,
      weekdayPatternsVersion: weekdayPatternsVersion ?? this.weekdayPatternsVersion,
      solverConfigVersion: solverConfigVersion ?? this.solverConfigVersion,
    );
  }

  /// Get display label for the period
  String get displayLabel {
    final months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return '${startDate.day}.${months[startDate.month - 1]} - ${endDate.day}.${months[endDate.month - 1]} ${endDate.year}';
  }

  /// Get short label
  String get shortLabel {
    return '${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
  }

  /// Get number of days in period
  int get dayCount => endDate.difference(startDate).inDays + 1;

  /// Get all dates in the period
  List<DateTime> get allDates {
    final dates = <DateTime>[];
    var current = startDate;
    while (!current.isAfter(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// Get first week dates (days 1-7)
  List<DateTime> get firstWeekDates => allDates.take(7).toList();

  /// Get second week dates (days 8-14)
  List<DateTime> get secondWeekDates => allDates.skip(7).take(7).toList();

  /// Check if date is in this period
  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  /// Get next valid status transition
  PeriodStatus? get nextStatus {
    switch (status) {
      case PeriodStatus.draft:
        return PeriodStatus.optimized;
      case PeriodStatus.optimized:
        return PeriodStatus.review;
      case PeriodStatus.review:
        return PeriodStatus.published;
      case PeriodStatus.published:
        return PeriodStatus.archived;
      case PeriodStatus.archived:
        return null;
    }
  }
}

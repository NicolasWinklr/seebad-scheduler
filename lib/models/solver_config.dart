// Solver configuration model
// Matches Firestore 'settings/solver/config' document

import 'package:cloud_firestore/cloud_firestore.dart';

/// Solver configuration with hard rules and soft weights
class SolverConfig {
  // Hard constraints
  final bool forbidLateToEarly;
  final int minRestHours;
  final int maxShiftsPerDayPerEmployee;

  // Sunday targets
  final int sundayTargetMin;
  final int sundayTargetMax;

  // Soft weights (0-100 scale)
  final int weightCoverageIdeal;
  final int weightCoverageUnderMin;
  final int weightHoursDeviation;
  final int weightSoftPreference;
  final int weightBlockPlanning;
  final int weightSundayFairness;
  final int weightWorkloadSmoothing;

  SolverConfig({
    this.forbidLateToEarly = true,
    this.minRestHours = 11,
    this.maxShiftsPerDayPerEmployee = 1,
    this.sundayTargetMin = 1,
    this.sundayTargetMax = 2,
    this.weightCoverageIdeal = 80,
    this.weightCoverageUnderMin = 200,
    this.weightHoursDeviation = 50,
    this.weightSoftPreference = 30,
    this.weightBlockPlanning = 40,
    this.weightSundayFairness = 60,
    this.weightWorkloadSmoothing = 25,
  });

  factory SolverConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SolverConfig(
      forbidLateToEarly: data['forbidLateToEarly'] as bool? ?? true,
      minRestHours: data['minRestHours'] as int? ?? 11,
      maxShiftsPerDayPerEmployee: data['maxShiftsPerDayPerEmployee'] as int? ?? 1,
      sundayTargetMin: data['sundayTargetMin'] as int? ?? 1,
      sundayTargetMax: data['sundayTargetMax'] as int? ?? 2,
      weightCoverageIdeal: data['weightCoverageIdeal'] as int? ?? 80,
      weightCoverageUnderMin: data['weightCoverageUnderMin'] as int? ?? 200,
      weightHoursDeviation: data['weightHoursDeviation'] as int? ?? 50,
      weightSoftPreference: data['weightSoftPreference'] as int? ?? 30,
      weightBlockPlanning: data['weightBlockPlanning'] as int? ?? 40,
      weightSundayFairness: data['weightSundayFairness'] as int? ?? 60,
      weightWorkloadSmoothing: data['weightWorkloadSmoothing'] as int? ?? 25,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'forbidLateToEarly': forbidLateToEarly,
      'minRestHours': minRestHours,
      'maxShiftsPerDayPerEmployee': maxShiftsPerDayPerEmployee,
      'sundayTargetMin': sundayTargetMin,
      'sundayTargetMax': sundayTargetMax,
      'weightCoverageIdeal': weightCoverageIdeal,
      'weightCoverageUnderMin': weightCoverageUnderMin,
      'weightHoursDeviation': weightHoursDeviation,
      'weightSoftPreference': weightSoftPreference,
      'weightBlockPlanning': weightBlockPlanning,
      'weightSundayFairness': weightSundayFairness,
      'weightWorkloadSmoothing': weightWorkloadSmoothing,
    };
  }

  SolverConfig copyWith({
    bool? forbidLateToEarly,
    int? minRestHours,
    int? maxShiftsPerDayPerEmployee,
    int? sundayTargetMin,
    int? sundayTargetMax,
    int? weightCoverageIdeal,
    int? weightCoverageUnderMin,
    int? weightHoursDeviation,
    int? weightSoftPreference,
    int? weightBlockPlanning,
    int? weightSundayFairness,
    int? weightWorkloadSmoothing,
  }) {
    return SolverConfig(
      forbidLateToEarly: forbidLateToEarly ?? this.forbidLateToEarly,
      minRestHours: minRestHours ?? this.minRestHours,
      maxShiftsPerDayPerEmployee: maxShiftsPerDayPerEmployee ?? this.maxShiftsPerDayPerEmployee,
      sundayTargetMin: sundayTargetMin ?? this.sundayTargetMin,
      sundayTargetMax: sundayTargetMax ?? this.sundayTargetMax,
      weightCoverageIdeal: weightCoverageIdeal ?? this.weightCoverageIdeal,
      weightCoverageUnderMin: weightCoverageUnderMin ?? this.weightCoverageUnderMin,
      weightHoursDeviation: weightHoursDeviation ?? this.weightHoursDeviation,
      weightSoftPreference: weightSoftPreference ?? this.weightSoftPreference,
      weightBlockPlanning: weightBlockPlanning ?? this.weightBlockPlanning,
      weightSundayFairness: weightSundayFairness ?? this.weightSundayFairness,
      weightWorkloadSmoothing: weightWorkloadSmoothing ?? this.weightWorkloadSmoothing,
    );
  }

  /// Default configuration
  static SolverConfig get defaults => SolverConfig();
}

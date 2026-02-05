// Solver provider for running the solver from UI

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'providers.dart';

/// Provider for running the solver
final solverProvider = FutureProvider.family<SolverResult, String>((ref, periodId) async {
  // Get all required data
  final periodRepo = ref.read(periodRepositoryProvider);
  final period = await periodRepo.get(periodId);
  if (period == null) throw Exception('Period not found');

  final employees = await ref.read(employeeRepositoryProvider).watchActive().first;
  final templates = await ref.read(shiftTemplateRepositoryProvider).watchActive().first;
  final config = await ref.read(settingsRepositoryProvider).getSolverConfig();
  
  // Get demand settings
  final baseline = await ref.read(baselineDemandProvider.future);
  final weekdayPatterns = await ref.read(settingsRepositoryProvider).getAllWeekdayPatterns();
  
  // Get locks
  final locks = await ref.read(locksProvider(periodId).future);

  // === NEW: Load assignments from other periods in the same month ===
  // This ensures cross-period tracking for hours, sundays, free days
  final allPeriods = await periodRepo.watchAll().first;
  final sameMonthPeriods = allPeriods.where((p) =>
    p.id != periodId && // Not current period
    _isOverlappingMonth(p, period) // Same month or overlapping
  ).toList();
  
  // Load assignments from those periods
  final existingAssignments = <Assignment>[];
  for (final otherPeriod in sameMonthPeriods) {
    final assignments = await periodRepo.getAssignments(otherPeriod.id);
    existingAssignments.addAll(assignments);
  }
  // ===================================================================

  // Create demand resolver
  final demandResolver = DemandResolver(
    baseline: baseline,
    weekdayPatterns: weekdayPatterns,
    dateOverrides: {}, // TODO: Load from period subcollection
    templates: templates,
  );

  // Create and run solver with cross-period data
  final solver = Solver(
    employees: employees,
    templates: templates,
    config: config,
    demandResolver: demandResolver,
    locks: locks,
    existingAssignments: existingAssignments,
  );

  return solver.solve(period);
});

/// Check if two periods overlap in the same calendar month
bool _isOverlappingMonth(Period a, Period b) {
  // Check if any part of period A falls in the same month as period B
  final aStartMonth = DateTime(a.startDate.year, a.startDate.month);
  final aEndMonth = DateTime(a.endDate.year, a.endDate.month);
  final bStartMonth = DateTime(b.startDate.year, b.startDate.month);
  final bEndMonth = DateTime(b.endDate.year, b.endDate.month);
  
  // Overlapping if months intersect
  return (aStartMonth.compareTo(bEndMonth) <= 0 && aEndMonth.compareTo(bStartMonth) >= 0);
}

/// State notifier for solver progress
class SolverProgressNotifier extends StateNotifier<SolverProgress> {
  SolverProgressNotifier() : super(SolverProgress.initial());

  void startPhase(SolverPhase phase, String message) {
    state = state.copyWith(
      currentPhase: phase,
      message: message,
      progress: _phaseProgress(phase),
    );
  }

  void complete(SolverResult result) {
    state = state.copyWith(
      currentPhase: SolverPhase.complete,
      message: 'Fertig!',
      progress: 1.0,
      result: result,
    );
  }

  void error(String message) {
    state = state.copyWith(
      currentPhase: SolverPhase.error,
      message: message,
    );
  }

  double _phaseProgress(SolverPhase phase) {
    switch (phase) {
      case SolverPhase.initial:
        return 0.0;
      case SolverPhase.generatingSlots:
        return 0.25;
      case SolverPhase.assigningEmployees:
        return 0.5;
      case SolverPhase.checkingViolations:
        return 0.75;
      case SolverPhase.finalizing:
        return 0.9;
      case SolverPhase.complete:
        return 1.0;
      case SolverPhase.error:
        return 0.0;
    }
  }
}

enum SolverPhase {
  initial,
  generatingSlots,
  assigningEmployees,
  checkingViolations,
  finalizing,
  complete,
  error,
}

class SolverProgress {
  final SolverPhase currentPhase;
  final String message;
  final double progress;
  final SolverResult? result;

  SolverProgress({
    required this.currentPhase,
    required this.message,
    required this.progress,
    this.result,
  });

  factory SolverProgress.initial() => SolverProgress(
    currentPhase: SolverPhase.initial,
    message: 'Initialisiere...',
    progress: 0.0,
  );

  SolverProgress copyWith({
    SolverPhase? currentPhase,
    String? message,
    double? progress,
    SolverResult? result,
  }) {
    return SolverProgress(
      currentPhase: currentPhase ?? this.currentPhase,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      result: result ?? this.result,
    );
  }
}

final solverProgressProvider = StateNotifierProvider<SolverProgressNotifier, SolverProgress>(
  (ref) => SolverProgressNotifier(),
);

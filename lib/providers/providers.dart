// Riverpod providers for state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/solver_service.dart'; // For SolverViolation

export 'solver_provider.dart';

// --- Service Providers ---

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) => EmployeeRepository());

final shiftTemplateRepositoryProvider = Provider<ShiftTemplateRepository>((ref) => ShiftTemplateRepository());

final periodRepositoryProvider = Provider<PeriodRepository>((ref) => PeriodRepository());

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());

// --- Auth Providers ---

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

// --- Employee Providers ---

final employeesProvider = StreamProvider<List<Employee>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchAll();
});

final activeEmployeesProvider = StreamProvider<List<Employee>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchActive();
});

// --- Shift Template Providers ---

final shiftTemplatesProvider = StreamProvider<List<ShiftTemplate>>((ref) {
  return ref.watch(shiftTemplateRepositoryProvider).watchAll();
});

final activeShiftTemplatesProvider = StreamProvider<List<ShiftTemplate>>((ref) {
  return ref.watch(shiftTemplateRepositoryProvider).watchActive();
});

// --- Period Providers ---

final periodsProvider = StreamProvider<List<Period>>((ref) {
  return ref.watch(periodRepositoryProvider).watchAll();
});

final selectedPeriodIdProvider = StateProvider<String?>((ref) => null);

final selectedPeriodProvider = Provider<Period?>((ref) {
  final periodId = ref.watch(selectedPeriodIdProvider);
  if (periodId == null) return null;
  
  final periods = ref.watch(periodsProvider).valueOrNull ?? [];
  return periods.cast<Period?>().firstWhere(
    (p) => p?.id == periodId,
    orElse: () => null,
  );
});

final assignmentsProvider = StreamProvider.family<List<Assignment>, String>((ref, periodId) {
  return ref.watch(periodRepositoryProvider).watchAssignments(periodId);
});

final locksProvider = StreamProvider.family<List<AssignmentLock>, String>((ref, periodId) {
  return ref.watch(periodRepositoryProvider).watchLocks(periodId);
});

final violationsProvider = StreamProvider.family<List<SolverViolation>, String>((ref, periodId) {
  return ref.watch(periodRepositoryProvider).watchViolations(periodId);
});

// --- Settings Providers ---

final solverConfigProvider = StreamProvider<SolverConfig>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSolverConfig();
});

final baselineDemandProvider = StreamProvider<Map<String, DemandOverride>>((ref) {
  return ref.watch(settingsRepositoryProvider).watchBaselineDemand();
});

final weekdayPatternsProvider = StreamProvider.family<Map<String, DemandOverride>, String>((ref, weekday) {
  return ref.watch(settingsRepositoryProvider).watchWeekdayPattern(weekday);
});

// --- UI State Providers ---

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

final selectedWeekToggleProvider = StateProvider<int>((ref) => 0); // 0 = both, 1 = week 1, 2 = week 2

final employeeListExpandedProvider = StateProvider<bool>((ref) => true);

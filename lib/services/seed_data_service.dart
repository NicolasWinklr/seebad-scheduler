// Seed data script
// Creates initial data for testing

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Seeds the database with initial data for testing
class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ShiftTemplateRepository _templateRepo = ShiftTemplateRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final PeriodRepository _periodRepo = PeriodRepository();

  /// Run all seeding operations
  Future<void> seedAll() async {
    await seedShiftTemplates();
    await seedEmployees();
    await seedSolverConfig();
    await seedSamplePeriod();
  }

  /// Seed the 9 predefined shift templates
  Future<void> seedShiftTemplates() async {
    await _templateRepo.seedTemplates();
  }

  /// Seed 5 sample employees
  Future<void> seedEmployees() async {
    final employees = [
      Employee(
        id: 'emp_1',
        firstName: 'Max',
        lastName: 'Mustermann',
        isActive: true,
        contractStatus: ContractStatus.fixangestellt,
        contractWorkPattern: ContractWorkPattern.unbeschraenkt,
        workloadPct: 100,
        areas: [ShiftArea.sauna, ShiftArea.hallenbadStrandbad],
        contractStart: DateTime(2020, 1, 1),
        softPreference: SoftPreference.egal,
        timeRestrictions: TimeRestrictions(global: TimeRestriction.unrestricted),
        freeDaysPerWeek: FreeDaysPerWeek(count: 2),
        absences: Absences(vacationRanges: [], shortUnavailability: []),
        notes: 'Erfahrener Mitarbeiter, kann alle Bereiche abdecken.',
      ),
      Employee(
        id: 'emp_2',
        firstName: 'Anna',
        lastName: 'Schmidt',
        isActive: true,
        contractStatus: ContractStatus.teilzeit,
        contractWorkPattern: ContractWorkPattern.nurUnterDerWoche,
        workloadPct: 60,
        areas: [ShiftArea.hallenbadStrandbad],
        contractStart: DateTime(2022, 6, 1),
        softPreference: SoftPreference.lieberUnterDerWoche,
        timeRestrictions: TimeRestrictions(global: TimeRestriction.nurVormittags),
        freeDaysPerWeek: FreeDaysPerWeek(count: 2),
        absences: Absences(vacationRanges: [], shortUnavailability: []),
        notes: 'Arbeitet nur vormittags unter der Woche.',
      ),
      Employee(
        id: 'emp_3',
        firstName: 'Thomas',
        lastName: 'Müller',
        isActive: true,
        contractStatus: ContractStatus.fixangestellt,
        contractWorkPattern: ContractWorkPattern.unbeschraenkt,
        workloadPct: 100,
        areas: [ShiftArea.sauna, ShiftArea.mili],
        contractStart: DateTime(2018, 3, 15),
        softPreference: SoftPreference.lieberUnterDerWoche,
        timeRestrictions: TimeRestrictions(global: TimeRestriction.unrestricted),
        freeDaysPerWeek: FreeDaysPerWeek(count: 2),
        absences: Absences(vacationRanges: [], shortUnavailability: []),
        notes: 'Spezialist für Sauna und Mili-Bereich.',
      ),
      Employee(
        id: 'emp_4',
        firstName: 'Lisa',
        lastName: 'Weber',
        isActive: true,
        contractStatus: ContractStatus.ferialer,
        contractWorkPattern: ContractWorkPattern.nurWochenende,
        workloadPct: 40,
        areas: [ShiftArea.hallenbadStrandbad],
        contractStart: DateTime(2025, 6, 1),
        contractEnd: DateTime(2025, 9, 30),
        softPreference: SoftPreference.keinWochenende,
        timeRestrictions: TimeRestrictions(global: TimeRestriction.unrestricted),
        freeDaysPerWeek: FreeDaysPerWeek(count: 1),
        absences: Absences(vacationRanges: [], shortUnavailability: []),
        notes: 'Sommerferialer, nur während Saison.',
      ),
      Employee(
        id: 'emp_5',
        firstName: 'Michael',
        lastName: 'Huber',
        isActive: true,
        contractStatus: ContractStatus.fixangestellt,
        contractWorkPattern: ContractWorkPattern.unbeschraenkt,
        workloadPct: 80,
        areas: [ShiftArea.sauna, ShiftArea.mili, ShiftArea.hallenbadStrandbad],
        contractStart: DateTime(2019, 9, 1),
        softPreference: SoftPreference.egal,
        timeRestrictions: TimeRestrictions(global: TimeRestriction.unrestricted),
        freeDaysPerWeek: FreeDaysPerWeek(count: 2),
        absences: Absences(
          vacationRanges: [
            DateRange(
              from: DateTime(2025, 7, 14),
              to: DateTime(2025, 7, 28),
            ),
          ],
          shortUnavailability: [],
        ),
        notes: 'Flexibler Allrounder. Urlaub vom 14.-28. Juli.',
      ),
    ];

    for (final emp in employees) {
      await _firestore.collection('employees').doc(emp.id).set(emp.toFirestore());
    }
  }

  /// Seed default solver config
  Future<void> seedSolverConfig() async {
    await _settingsRepo.seedDefaults();
  }

  /// Seed a sample period for current month
  Future<void> seedSamplePeriod() async {
    final now = DateTime.now();
    final period = Period.create(year: now.year, month: now.month);
    await _periodRepo.create(period);
  }
}

// Seed data script
// Creates initial data for testing

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Seeds the database with initial data for testing
class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ShiftTemplateRepository _templateRepo = ShiftTemplateRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final PeriodRepository _periodRepo = PeriodRepository();
  final Random _random = Random();

  /// Delete all test data
  Future<void> clearAllData() async {
    print('Clearing all data...');
    
    // Employees
    final employees = await _firestore.collection('employees').get();
    for (var doc in employees.docs) await doc.reference.delete();

    // Periods and their subcollections
    final periods = await _firestore.collection('periods').get();
    for (var doc in periods.docs) {
      final assignments = await doc.reference.collection('assignments').get();
      for (var a in assignments.docs) await a.reference.delete();
      
      final violations = await doc.reference.collection('violations').get();
      for (var v in violations.docs) await v.reference.delete();
      
      final locks = await doc.reference.collection('locks').get();
      for (var l in locks.docs) await l.reference.delete();

      await doc.reference.delete();
    }

    // Shift Templates
    final templates = await _firestore.collection('shift_templates').get();
    for (var doc in templates.docs) await doc.reference.delete();
    
    print('Data cleared.');
  }

  /// Run all seeding operations
  Future<void> seedAll() async {
    await clearAllData(); // Ensure clean slate
    await seedShiftTemplates();
    await seedEmployees();
    await seedSolverConfig();
    await seedSamplePeriod();
  }

  /// Seed the specific shift templates requested by the user
  Future<void> seedShiftTemplates() async {
    final templates = [
      // Bad (Hallenbad)
      ShiftTemplate(
        code: 'B-Frueh',
        label: 'B-Früh',
        area: ShiftArea.hallenbadStrandbad,
        site: ShiftSite.hallenbad,
        daySegment: DaySegment.am,
        minStaffDefault: 1,
        idealStaffDefault: 1,
        defaultStart: '06:00',
        defaultEnd: '14:00',
        isActive: true,
      ),
      ShiftTemplate(
        code: 'B-Spaet',
        label: 'B-Spät',
        area: ShiftArea.hallenbadStrandbad,
        site: ShiftSite.hallenbad,
        daySegment: DaySegment.pm,
        minStaffDefault: 1,
        idealStaffDefault: 1,
        defaultStart: '14:00',
        defaultEnd: '22:00',
        isActive: true,
      ),
      ShiftTemplate(
        code: 'B-Mitte',
        label: 'B-Mitte',
        area: ShiftArea.hallenbadStrandbad,
        site: ShiftSite.hallenbad,
        daySegment: DaySegment.allday,
        minStaffDefault: 1,
        idealStaffDefault: 1,
        defaultStart: '10:00',
        defaultEnd: '18:00',
        isActive: true,
      ),
      
      // Sauna
      ShiftTemplate(
        code: 'S-Frueh',
        label: 'S-Früh',
        area: ShiftArea.sauna,
        daySegment: DaySegment.am,
        minStaffDefault: 1,
        idealStaffDefault: 1,
        defaultStart: '09:00',
        defaultEnd: '15:00',
        isActive: true,
      ),
      ShiftTemplate(
        code: 'S-Spaet',
        label: 'S-Spät',
        area: ShiftArea.sauna,
        daySegment: DaySegment.pm,
        minStaffDefault: 1,
        idealStaffDefault: 1,
        defaultStart: '15:00',
        defaultEnd: '22:00',
        isActive: true,
      ),

      // Strandbad / Mili specifics
      ShiftTemplate(
        code: 'SB-Mitte',
        label: 'SB-Mitte',
        area: ShiftArea.hallenbadStrandbad,
        site: ShiftSite.strandbad,
        daySegment: DaySegment.allday,
        minStaffDefault: 1,
        idealStaffDefault: 1,
        defaultStart: '10:00',
        defaultEnd: '18:00',
        isActive: true,
      ),
      ShiftTemplate(
        code: 'Mili',
        label: 'Militärbad',
        area: ShiftArea.mili,
        daySegment: DaySegment.allday,
        minStaffDefault: 1,
        idealStaffDefault: 2, // Often needs more cover?
        defaultStart: '09:00',
        defaultEnd: '19:00',
        isActive: true,
      ),
      ShiftTemplate(
        code: 'VM-SB',
        label: 'VM-SB',
        area: ShiftArea.hallenbadStrandbad,
        site: ShiftSite.strandbad,
        daySegment: DaySegment.am,
        minStaffDefault: 1,
        idealStaffDefault: 1,
        defaultStart: '08:00',
        defaultEnd: '14:00',
        isActive: true,
      ),
      ShiftTemplate(
        code: 'NM-SB',
        label: 'NM-SB',
        area: ShiftArea.hallenbadStrandbad,
        site: ShiftSite.strandbad,
        daySegment: DaySegment.pm,
        minStaffDefault: 2, // Requested by user: mind 2, besser 3
        idealStaffDefault: 3,
        defaultStart: '14:00',
        defaultEnd: '20:00',
        isActive: true,
      ),
    ];

    print('Seeding ${templates.length} shift templates...');
    for (final t in templates) {
      await _templateRepo.create(t);
    }
  }

  /// Seed employees based on the roster image and requirements
  Future<void> seedEmployees() async {
    // List based on provided image
    final staffList = [
      // Name, Role (fix/ferial), Areas
      ('Gerold', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad, ShiftArea.sauna]),
      ('Wolfi Ba', ContractStatus.fixangestellt, [ShiftArea.sauna, ShiftArea.hallenbadStrandbad]),
      ('Olivier', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad, ShiftArea.sauna, ShiftArea.mili]),
      ('Pascal', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad, ShiftArea.mili, ShiftArea.sauna]),
      ('Anna H.', ContractStatus.fixangestellt, [ShiftArea.sauna, ShiftArea.hallenbadStrandbad]),
      ('Gabriel', ContractStatus.fixangestellt, [ShiftArea.sauna, ShiftArea.hallenbadStrandbad, ShiftArea.mili]),
      ('Dieter', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad, ShiftArea.mili]),
      ('Elena', ContractStatus.fixangestellt, [ShiftArea.mili, ShiftArea.hallenbadStrandbad, ShiftArea.sauna]),
      ('Roman', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad, ShiftArea.mili]),
      ('Eliakim', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad, ShiftArea.mili]),
      ('Ada', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Olivia', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad, ShiftArea.mili]),
      ('Linus L.', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Anna M.', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad, ShiftArea.mili]),
      ('Manuel', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]), // Hat "KURS"?
      ('Alina', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Noemi', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Andre', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Max', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Linus Ob', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Karim', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Hakam', ContractStatus.ferialer, [ShiftArea.hallenbadStrandbad]),
      ('Marco', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad]),
      ('Johanna', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad]),
      ('Thomas', ContractStatus.fixangestellt, [ShiftArea.mili, ShiftArea.hallenbadStrandbad]),
      ('Wolfi Sch', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad]),
      ('Sophie', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad, ShiftArea.mili]),
      ('Julien', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad]),
      ('Sascha', ContractStatus.fixangestellt, [ShiftArea.hallenbadStrandbad]),
    ];

    print('Seeding ${staffList.length} employees...');
    
    // Seed employees with some randomness
    for (var i = 0; i < staffList.length; i++) {
        final entry = staffList[i];
        final nameParts = entry.$1.split(' ');
        final firstName = nameParts[0];
        final lastName = nameParts.length > 1 ? nameParts[1] : '';
        final status = entry.$2;
        final areas = entry.$3;

        final isFerial = status == ContractStatus.ferialer;
        
        // Randomize workload slightly
        final workload = isFerial 
            ? [20, 30, 40, 50, 60][_random.nextInt(5)] 
            : [80, 100][_random.nextInt(2)];

        // Randomize vacations for 50% of staff
        final absences = <DateRange>[];
        if (_random.nextBool()) { 
           final today = DateTime.now();
           // Vacation starts within next 60 days
           final start = today.add(Duration(days: _random.nextInt(60)));
           // Duration 3-14 days
           final duration = _random.nextInt(12) + 3;
           absences.add(DateRange(from: start, to: start.add(Duration(days: duration))));
        }

        final emp = Employee(
            id: 'emp_${firstName.toLowerCase()}_${lastName.toLowerCase()}_${i}',
            firstName: firstName,
            lastName: lastName,
            isActive: true,
            contractStatus: status,
            contractWorkPattern: ContractWorkPattern.unbeschraenkt,
            workloadPct: workload,
            areas: areas,
            contractStart: DateTime(2023, 1, 1),
            softPreference: SoftPreference.egal,
            timeRestrictions: TimeRestrictions(global: TimeRestriction.unrestricted),
            freeDaysPerWeek: FreeDaysPerWeek(count: 2),
            absences: Absences(vacationRanges: absences, shortUnavailability: []),
            notes: isFerial ? 'Ferialer / Aushilfe' : 'Stammpersonal',
        );

        await _firestore.collection('employees').doc(emp.id).set(emp.toFirestore());
    }
  }

  /// Seed default solver config
  Future<void> seedSolverConfig() async {
    await _settingsRepo.seedDefaults();
  }

  /// Seed a sample period for current month and next month
  Future<void> seedSamplePeriod() async {
    final now = DateTime.now();
    
    // Create current 2-week period (starting this week's Monday)
    final period1 = Period.createWeeks(startDate: now);
    await _periodRepo.create(period1);
    
    // Create next 2-week period
    final nextStart = period1.startDate.add(const Duration(days: 14));
    final period2 = Period.createWeeks(startDate: nextStart);
    await _periodRepo.create(period2);
  }
}

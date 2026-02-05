// Settings repository for solver config and demand settings

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/solver_config.dart';
import '../models/demand.dart';

/// Repository for settings data access
class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Solver Config ---

  DocumentReference<Map<String, dynamic>> get _solverConfigDoc =>
      _firestore.collection('settings').doc('solver').collection('config').doc('default');

  /// Watch solver config
  Stream<SolverConfig> watchSolverConfig() {
    return _solverConfigDoc.snapshots().map((doc) {
      if (!doc.exists) return SolverConfig.defaults;
      return SolverConfig.fromFirestore(doc);
    });
  }

  /// Get solver config
  Future<SolverConfig> getSolverConfig() async {
    final doc = await _solverConfigDoc.get();
    if (!doc.exists) return SolverConfig.defaults;
    return SolverConfig.fromFirestore(doc);
  }

  /// Save solver config
  Future<void> saveSolverConfig(SolverConfig config) async {
    await _solverConfigDoc.set(config.toFirestore());
  }

  // --- Baseline Demand ---

  CollectionReference<Map<String, dynamic>> get _baselineDemandCollection =>
      _firestore.collection('settings').doc('shiftDemand').collection('baseline');

  /// Watch baseline demand overrides
  Stream<Map<String, DemandOverride>> watchBaselineDemand() {
    return _baselineDemandCollection.snapshots().map((snapshot) {
      final map = <String, DemandOverride>{};
      for (final doc in snapshot.docs) {
        map[doc.id] = DemandOverride.fromFirestore(doc);
      }
      return map;
    });
  }

  /// Save baseline demand override
  Future<void> saveBaselineDemand(DemandOverride override) async {
    await _baselineDemandCollection.doc(override.templateCode).set(override.toFirestore());
  }

  // --- Weekday Patterns ---

  CollectionReference<Map<String, dynamic>> _weekdayPatternCollection(String weekday) =>
      _firestore.collection('settings').doc('shiftDemand')
          .collection('weekdayPatterns').doc(weekday).collection('patterns');

  /// Watch weekday pattern overrides
  Stream<Map<String, DemandOverride>> watchWeekdayPattern(String weekday) {
    return _weekdayPatternCollection(weekday).snapshots().map((snapshot) {
      final map = <String, DemandOverride>{};
      for (final doc in snapshot.docs) {
        map[doc.id] = DemandOverride.fromFirestore(doc);
      }
      return map;
    });
  }

  /// Save weekday pattern override
  Future<void> saveWeekdayPattern(String weekday, DemandOverride override) async {
    await _weekdayPatternCollection(weekday).doc(override.templateCode).set(override.toFirestore());
  }

  /// Get all weekday patterns
  Future<Map<String, Map<String, DemandOverride>>> getAllWeekdayPatterns() async {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final result = <String, Map<String, DemandOverride>>{};
    
    for (final weekday in weekdays) {
      final snapshot = await _weekdayPatternCollection(weekday).get();
      result[weekday] = {};
      for (final doc in snapshot.docs) {
        result[weekday]![doc.id] = DemandOverride.fromFirestore(doc);
      }
    }
    return result;
  }

  /// Seed default solver config
  Future<void> seedDefaults() async {
    final doc = await _solverConfigDoc.get();
    if (!doc.exists) {
      await saveSolverConfig(SolverConfig.defaults);
    }
  }
}

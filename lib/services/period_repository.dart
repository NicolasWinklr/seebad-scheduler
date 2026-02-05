// Period repository for planning periods

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/period.dart';
import '../models/assignment.dart';

/// Repository for period and assignment data access
class PeriodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('periods');

  /// Get all periods stream
  Stream<List<Period>> watchAll() {
    return _collection
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Period.fromFirestore(doc)).toList());
  }

  /// Get single period
  Future<Period?> get(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Period.fromFirestore(doc);
  }

  /// Create period
  Future<String> create(Period period) async {
    await _collection.doc(period.id).set(period.toFirestore());
    return period.id;
  }

  /// Update period
  Future<void> update(Period period) async {
    await _collection.doc(period.id).update(period.toFirestore());
  }

  /// Update period status
  Future<void> updateStatus(String periodId, PeriodStatus status) async {
    await _collection.doc(periodId).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Assignments subcollection ---

  CollectionReference<Map<String, dynamic>> _assignmentsCollection(String periodId) =>
      _collection.doc(periodId).collection('assignments');

  /// Watch assignments for a period
  Stream<List<Assignment>> watchAssignments(String periodId) {
    return _assignmentsCollection(periodId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Assignment.fromFirestore(doc)).toList());
  }

  /// Get assignments for a specific date
  Future<List<Assignment>> getAssignmentsForDate(String periodId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await _assignmentsCollection(periodId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    
    return snapshot.docs.map((doc) => Assignment.fromFirestore(doc)).toList();
  }

  /// Create or update assignment
  Future<void> saveAssignment(String periodId, Assignment assignment) async {
    await _assignmentsCollection(periodId).doc(assignment.id).set(
      assignment.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Delete assignment
  Future<void> deleteAssignment(String periodId, String assignmentId) async {
    await _assignmentsCollection(periodId).doc(assignmentId).delete();
  }

  /// Batch save assignments (for solver)
  Future<void> batchSaveAssignments(String periodId, List<Assignment> assignments) async {
    final batch = _firestore.batch();
    for (final assignment in assignments) {
      batch.set(
        _assignmentsCollection(periodId).doc(assignment.id),
        assignment.toFirestore(),
      );
    }
    await batch.commit();
  }

  /// Clear all assignments for a period (before solver run)
  Future<void> clearAssignments(String periodId) async {
    final snapshot = await _assignmentsCollection(periodId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Locks subcollection ---

  CollectionReference<Map<String, dynamic>> _locksCollection(String periodId) =>
      _collection.doc(periodId).collection('locks');

  /// Watch locks for a period
  Stream<List<AssignmentLock>> watchLocks(String periodId) {
    return _locksCollection(periodId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AssignmentLock.fromFirestore(doc)).toList());
  }

  /// Add lock
  Future<void> addLock(String periodId, AssignmentLock lock) async {
    await _locksCollection(periodId).doc(lock.docId).set(lock.toFirestore());
  }

  /// Remove lock
  Future<void> removeLock(String periodId, String lockId) async {
    await _locksCollection(periodId).doc(lockId).delete();
  }
}

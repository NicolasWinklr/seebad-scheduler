// Employee repository for Firestore CRUD operations

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';

/// Repository for employee data access
class EmployeeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('employees');

  /// Get all employees stream
  Stream<List<Employee>> watchAll() {
    return _collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList());
  }

  /// Get active employees stream
  Stream<List<Employee>> watchActive() {
    return _collection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList());
  }

  /// Get single employee
  Future<Employee?> get(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Employee.fromFirestore(doc);
  }

  /// Create employee
  Future<String> create(Employee employee) async {
    final doc = await _collection.add(employee.toFirestore());
    return doc.id;
  }

  /// Update employee
  Future<void> update(Employee employee) async {
    await _collection.doc(employee.id).update(employee.toFirestore());
  }

  /// Delete employee (soft delete by setting isActive to false)
  Future<void> deactivate(String id) async {
    await _collection.doc(id).update({'isActive': false, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Get employees by area
  Stream<List<Employee>> watchByArea(String area) {
    return _collection
        .where('isActive', isEqualTo: true)
        .where('areas', arrayContains: area)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList());
  }
}

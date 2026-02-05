// Shift template repository

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_template.dart';

/// Repository for shift template data access
class ShiftTemplateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('shiftTemplates');

  /// Get all shift templates stream
  Stream<List<ShiftTemplate>> watchAll() {
    return _collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ShiftTemplate.fromFirestore(doc)).toList());
  }

  /// Get active shift templates
  Stream<List<ShiftTemplate>> watchActive() {
    return _collection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ShiftTemplate.fromFirestore(doc)).toList());
  }

  /// Get single template
  Future<ShiftTemplate?> get(String code) async {
    final doc = await _collection.doc(code).get();
    if (!doc.exists) return null;
    return ShiftTemplate.fromFirestore(doc);
  }

  /// Update template (isActive, defaults)
  Future<void> update(ShiftTemplate template) async {
    await _collection.doc(template.code).set(template.toFirestore(), SetOptions(merge: true));
  }

  /// Create new template
  Future<void> create(ShiftTemplate template) async {
    await _collection.doc(template.code).set(template.toFirestore());
  }

  /// Delete template
  Future<void> delete(String code) async {
    await _collection.doc(code).delete();
  }

  /// Seed predefined templates
  Future<void> seedTemplates() async {
    final batch = _firestore.batch();
    for (final template in ShiftTemplate.predefined) {
      batch.set(_collection.doc(template.code), template.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}

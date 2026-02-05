// Demand model for staffing requirements

import 'package:cloud_firestore/cloud_firestore.dart';

/// Demand override model
class DemandOverride {
  final String templateCode;
  final int? min;
  final int? ideal;
  final int? max;
  final bool? isActive;

  DemandOverride({
    required this.templateCode,
    this.min,
    this.ideal,
    this.max,
    this.isActive,
  });

  bool get hasOverrides => min != null || ideal != null || max != null || isActive != null;

  factory DemandOverride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DemandOverride(
      templateCode: doc.id.split('#').last,
      min: data['min'] as int?,
      ideal: data['ideal'] as int?,
      max: data['max'] as int?,
      isActive: data['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'templateCode': templateCode,
      'min': min,
      'ideal': ideal,
      'max': max,
      'isActive': isActive,
    };
  }
}

/// Date-specific demand override
class DateDemandOverride extends DemandOverride {
  final DateTime date;

  DateDemandOverride({
    required this.date,
    required super.templateCode,
    super.min,
    super.ideal,
    super.max,
    super.isActive,
  });

  factory DateDemandOverride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final parts = doc.id.split('#');
    final dateStr = parts.first;
    final dateParts = dateStr.split('-');
    return DateDemandOverride(
      date: DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2])),
      templateCode: parts.last,
      min: data['min'] as int?,
      ideal: data['ideal'] as int?,
      max: data['max'] as int?,
      isActive: data['isActive'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'templateCode': templateCode,
      'min': min,
      'ideal': ideal,
      'max': max,
      'isActive': isActive,
    };
  }

  String get docId {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$dateStr#$templateCode';
  }
}

/// Resolved demand after applying all overrides
class ResolvedDemand {
  final String templateCode;
  final DateTime date;
  final int min;
  final int ideal;
  final int max;
  final bool isActive;
  final String source;

  ResolvedDemand({
    required this.templateCode,
    required this.date,
    required this.min,
    required this.ideal,
    required this.max,
    required this.isActive,
    required this.source,
  });

  bool get shouldGenerateSlots => isActive && ideal > 0;
}

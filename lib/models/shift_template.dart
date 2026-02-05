// Shift template model for defining shift types
// Matches Firestore 'shiftTemplates' collection schema

import 'package:cloud_firestore/cloud_firestore.dart';

/// Day segment for shifts
enum DaySegment {
  am('AM'),
  pm('PM'),
  allday('ALLDAY');

  final String value;
  const DaySegment(this.value);

  static DaySegment fromString(String value) {
    return DaySegment.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase() || e.value == value,
      orElse: () => DaySegment.allday,
    );
  }

  String get labelGerman {
    switch (this) {
      case DaySegment.am:
        return 'Vormittags';
      case DaySegment.pm:
        return 'Nachmittags';
      case DaySegment.allday:
        return 'Ganztags';
    }
  }
}

/// Areas where employees can work
class ShiftArea {
  static const String sauna = 'Sauna';
  static const String mili = 'Mili';
  static const String hallenbadStrandbad = 'Hallenbad/Strandbad';

  static List<String> get all => [sauna, mili, hallenbadStrandbad];
}

/// Sites within Hallenbad/Strandbad
class ShiftSite {
  static const String hallenbad = 'B';
  static const String strandbad = 'SB';

  static List<String> get all => [hallenbad, strandbad];

  static String? labelGerman(String? site) {
    switch (site) {
      case hallenbad:
        return 'Hallenbad';
      case strandbad:
        return 'Strandbad';
      default:
        return null;
    }
  }
}

/// Shift template definition
class ShiftTemplate {
  final String code;
  final String label;
  final String area;
  final String? site;
  final DaySegment daySegment;
  final int minStaffDefault;
  final int idealStaffDefault;
  final bool isActive;
  final String? defaultStart;
  final String? defaultEnd;

  ShiftTemplate({
    required this.code,
    required this.label,
    required this.area,
    this.site,
    required this.daySegment,
    this.minStaffDefault = 1,
    this.idealStaffDefault = 1,
    this.isActive = true,
    this.defaultStart,
    this.defaultEnd,
  });

  /// Factory from Firestore document
  factory ShiftTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftTemplate(
      code: doc.id,
      label: data['label'] as String? ?? doc.id,
      area: data['area'] as String? ?? '',
      site: data['site'] as String?,
      daySegment: DaySegment.fromString(data['daySegment'] as String? ?? 'ALLDAY'),
      minStaffDefault: data['minStaffDefault'] as int? ?? 1,
      idealStaffDefault: data['idealStaffDefault'] as int? ?? 1,
      isActive: data['isActive'] as bool? ?? true,
      defaultStart: data['defaultStart'] as String?,
      defaultEnd: data['defaultEnd'] as String?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'area': area,
      'site': site,
      'daySegment': daySegment.value,
      'minStaffDefault': minStaffDefault,
      'idealStaffDefault': idealStaffDefault,
      'isActive': isActive,
      'defaultStart': defaultStart,
      'defaultEnd': defaultEnd,
    };
  }

  /// Copy with method
  ShiftTemplate copyWith({
    String? code,
    String? label,
    String? area,
    String? site,
    DaySegment? daySegment,
    int? minStaffDefault,
    int? idealStaffDefault,
    bool? isActive,
    String? defaultStart,
    String? defaultEnd,
  }) {
    return ShiftTemplate(
      code: code ?? this.code,
      label: label ?? this.label,
      area: area ?? this.area,
      site: site ?? this.site,
      daySegment: daySegment ?? this.daySegment,
      minStaffDefault: minStaffDefault ?? this.minStaffDefault,
      idealStaffDefault: idealStaffDefault ?? this.idealStaffDefault,
      isActive: isActive ?? this.isActive,
      defaultStart: defaultStart ?? this.defaultStart,
      defaultEnd: defaultEnd ?? this.defaultEnd,
    );
  }

  /// Get area badge color for UI
  int get areaColor {
    switch (area) {
      case ShiftArea.sauna:
        return 0xFFFF9800; // Orange
      case ShiftArea.mili:
        return 0xFF4CAF50; // Green
      case ShiftArea.hallenbadStrandbad:
        return 0xFF005DA9; // Seebad Blue
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Display text with site info
  String get displayLabel {
    if (site != null) {
      return '$label (${ShiftSite.labelGerman(site)})';
    }
    return label;
  }

  /// Predefined shift templates
  static List<ShiftTemplate> get predefined => [
        ShiftTemplate(
          code: 'S-Frueh',
          label: 'S-Früh',
          area: ShiftArea.sauna,
          daySegment: DaySegment.am,
          minStaffDefault: 1,
          idealStaffDefault: 1,
          defaultStart: '06:00',
          defaultEnd: '14:00',
        ),
        ShiftTemplate(
          code: 'S-Spaet',
          label: 'S-Spät',
          area: ShiftArea.sauna,
          daySegment: DaySegment.pm,
          minStaffDefault: 1,
          idealStaffDefault: 1,
          defaultStart: '14:00',
          defaultEnd: '22:00',
        ),
        ShiftTemplate(
          code: 'Mili',
          label: 'Mili',
          area: ShiftArea.mili,
          daySegment: DaySegment.allday,
          minStaffDefault: 2,
          idealStaffDefault: 2,
          defaultStart: '09:00',
          defaultEnd: '19:00',
        ),
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
        ),
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
        ),
        ShiftTemplate(
          code: 'VM-SB',
          label: 'VM-SB',
          area: ShiftArea.hallenbadStrandbad,
          site: ShiftSite.strandbad,
          daySegment: DaySegment.am,
          minStaffDefault: 1,
          idealStaffDefault: 1,
          defaultStart: '06:00',
          defaultEnd: '14:00',
        ),
        ShiftTemplate(
          code: 'NM-SB',
          label: 'NM-SB',
          area: ShiftArea.hallenbadStrandbad,
          site: ShiftSite.strandbad,
          daySegment: DaySegment.pm,
          minStaffDefault: 2,
          idealStaffDefault: 3,
          defaultStart: '14:00',
          defaultEnd: '20:00',
        ),
      ];
}

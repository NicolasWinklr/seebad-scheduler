// Excel export service
// Generates Excel schedule with multiple sheets

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Excel export service for generating schedule spreadsheets
class ExcelExportService {
  /// Generate Excel for a period's schedule
  Future<Uint8List> generateScheduleExcel({
    required Period period,
    required List<Assignment> assignments,
    required List<Employee> employees,
    required List<ShiftTemplate> templates,
  }) async {
    final excel = Excel.createExcel();
    
    // Sheet 1: Dienstplan
    _buildScheduleSheet(excel, period, assignments, employees, templates);
    
    // Sheet 2: Legende
    _buildLegendSheet(excel, templates);
    
    // Sheet 3: Zusammenfassung
    _buildSummarySheet(excel, period, assignments, employees, templates);

    // Remove default sheet
    excel.delete('Sheet1');

    return Uint8List.fromList(excel.encode()!);
  }

  void _buildScheduleSheet(
    Excel excel,
    Period period,
    List<Assignment> assignments,
    List<Employee> employees,
    List<ShiftTemplate> templates,
  ) {
    final sheet = excel['Dienstplan'];
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final dateFormat = DateFormat('d.M');
    final dates = period.allDates.take(14).toList();

    // Header row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Schicht');
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: 0)).value = 
        TextCellValue('${weekdays[date.weekday - 1]} ${dateFormat.format(date)}');
    }

    // Data rows
    final activeTemplates = templates.where((t) => t.isActive).toList();
    for (int row = 0; row < activeTemplates.length; row++) {
      final template = activeTemplates[row];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1)).value = 
        TextCellValue(template.label);

      for (int col = 0; col < dates.length; col++) {
        final date = dates[col];
        final dayAssignments = assignments.where((a) =>
          a.date.year == date.year &&
          a.date.month == date.month &&
          a.date.day == date.day &&
          a.shiftTemplateCode == template.code
        ).toList();

        if (dayAssignments.isNotEmpty) {
          final names = dayAssignments.map((a) {
            final emp = employees.cast<Employee?>().firstWhere(
              (e) => e?.id == a.employeeId,
              orElse: () => null,
            );
            return emp?.lastName ?? '?';
          }).join(', ');
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col + 1, rowIndex: row + 1)).value = 
            TextCellValue(names);
        }
      }
    }
  }

  void _buildLegendSheet(Excel excel, List<ShiftTemplate> templates) {
    final sheet = excel['Legende'];
    
    // Headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Code');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Label');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('Bereich');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('Standort');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue('Startzeit');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = TextCellValue('Endzeit');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = TextCellValue('Segment');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0)).value = TextCellValue('Min Personal');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0)).value = TextCellValue('Ideal Personal');

    for (int i = 0; i < templates.length; i++) {
      final t = templates[i];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(t.code);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(t.label);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(t.area);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = TextCellValue(ShiftSite.labelGerman(t.site) ?? '—');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = TextCellValue(t.defaultStart ?? '—');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = TextCellValue(t.defaultEnd ?? '—');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = TextCellValue(t.daySegment.labelGerman);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 1)).value = IntCellValue(t.minStaffDefault);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: i + 1)).value = IntCellValue(t.idealStaffDefault);
    }
  }

  void _buildSummarySheet(
    Excel excel,
    Period period,
    List<Assignment> assignments,
    List<Employee> employees,
    List<ShiftTemplate> templates,
  ) {
    final sheet = excel['Zusammenfassung'];
    
    // Period info
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Periode');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue(period.displayLabel);
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Status');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = TextCellValue(period.status.labelGerman);
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Gesamte Schichten');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value = IntCellValue(assignments.length);

    // Employee summary
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = TextCellValue('Mitarbeiter');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = TextCellValue('Anzahl Schichten');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 4)).value = TextCellValue('Stunden (ca.)');

    int row = 5;
    for (final emp in employees.where((e) => e.isActive)) {
      final empAssignments = assignments.where((a) => a.employeeId == emp.id).toList();
      if (empAssignments.isEmpty) continue;

      // Estimate hours based on day segment
      double totalHours = 0;
      for (final a in empAssignments) {
        final t = templates.cast<ShiftTemplate?>().firstWhere(
          (t) => t?.code == a.shiftTemplateCode,
          orElse: () => null,
        );
        if (t != null) {
          totalHours += t.daySegment == DaySegment.allday ? 8 : 6;
        }
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(emp.fullName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = IntCellValue(empAssignments.length);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = DoubleCellValue(totalHours);
      row++;
    }
  }
}

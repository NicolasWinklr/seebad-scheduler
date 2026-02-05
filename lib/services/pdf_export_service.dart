// PDF export service
// Generates printable PDF schedule

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';

/// PDF export service for generating schedule PDFs
class PdfExportService {
  /// Generate PDF for a period's schedule
  Future<Uint8List> generateSchedulePdf({
    required Period period,
    required List<Assignment> assignments,
    required List<Employee> employees,
    required List<ShiftTemplate> templates,
  }) async {
    final pdf = pw.Document();
    
    final dateFormat = DateFormat('dd.MM.yyyy');
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    // Group by weeks
    final week1Dates = period.firstWeekDates;
    final week2Dates = period.secondWeekDates;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildHeader(period, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Text('Woche 1: ${dateFormat.format(week1Dates.first)} - ${dateFormat.format(week1Dates.last)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 10),
          _buildWeekTable(week1Dates, assignments, employees, templates, weekdays),
          pw.SizedBox(height: 20),
          pw.Text('Woche 2: ${dateFormat.format(week2Dates.first)} - ${dateFormat.format(week2Dates.last)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 10),
          _buildWeekTable(week2Dates, assignments, employees, templates, weekdays),
          pw.SizedBox(height: 20),
          _buildLegend(templates),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Period period, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Dienstplan Strandbad Bregenz',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('${dateFormat.format(period.startDate)} - ${dateFormat.format(period.endDate)}',
                style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#005DA9'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              period.status.labelGerman.toUpperCase(),
              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generiert am ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text('Seite ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildWeekTable(
    List<DateTime> dates,
    List<Assignment> assignments,
    List<Employee> employees,
    List<ShiftTemplate> templates,
    List<String> weekdays,
  ) {
    final dateFormat = DateFormat('d.M');
    
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellHeight: 30,
      cellAlignment: pw.Alignment.center,
      headers: [
        'Schicht',
        ...dates.map((d) => '${weekdays[d.weekday - 1]}\n${dateFormat.format(d)}'),
      ],
      data: templates.where((t) => t.isActive).map((template) {
        return [
          template.label,
          ...dates.map((date) {
            final dayAssignments = assignments.where((a) =>
              a.date.year == date.year &&
              a.date.month == date.month &&
              a.date.day == date.day &&
              a.shiftTemplateCode == template.code
            ).toList();
            
            if (dayAssignments.isEmpty) return '—';
            
            return dayAssignments.map((a) {
              final emp = employees.cast<Employee?>().firstWhere(
                (e) => e?.id == a.employeeId,
                orElse: () => null,
              );
              return emp?.lastName ?? '?';
            }).join('\n');
          }),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildLegend(List<ShiftTemplate> templates) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Legende', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 20,
          runSpacing: 4,
          children: templates.where((t) => t.isActive).map((t) => pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 10,
                height: 10,
                color: PdfColor.fromInt(t.areaColor),
              ),
              pw.SizedBox(width: 4),
              pw.Text('${t.label}: ${t.defaultStart ?? '—'}–${t.defaultEnd ?? '—'} (${t.area})',
                style: const pw.TextStyle(fontSize: 8)),
            ],
          )).toList(),
        ),
      ],
    );
  }
}

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  static Future<void> generateAndShareDoctorReport({
    required String patientName,
    required String diabetesType,
    required int age,
    required String gender,
    required double weightKg,
    required double avgGlucose,
    required double estimatedHba1c,
    required double recordedHba1c,
    required int adherenceRate,
    required List<dynamic> readings,
    required String timeframe,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DIACARE HEALTHCARE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#00897B'),
                      ),
                    ),
                    pw.Text(
                      'Clinical Diabetes Management Summary Report',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Report Date: $dateStr', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Timeframe: ${timeframe.toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#00897B')),
            pw.SizedBox(height: 12),

            // Patient Demographics Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Patient Name: $patientName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Diagnosis: $diabetesType', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Age / Sex: $age yrs / $gender', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Recorded Weight: $weightKg kg', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Medication Adherence: $adherenceRate%', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#10B981'))),
                      pw.SizedBox(height: 4),
                      pw.Text('Lab HbA1c: $recordedHba1c%', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Key Clinical Vitals Summary Box
            pw.Text('Key Clinical Analytics', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildMetricBox('Average Glucose', '$avgGlucose mg/dL', 'Target: 70-140 mg/dL'),
                pw.SizedBox(width: 8),
                _buildMetricBox('Estimated HbA1c', '$estimatedHba1c %', 'Based on recent readings'),
                pw.SizedBox(width: 8),
                _buildMetricBox('Medication Adherence', '$adherenceRate %', 'Scheduled doses taken'),
              ],
            ),
            pw.SizedBox(height: 16),

            // Glucose Readings Log Table
            pw.Text('Recent Glucose Records & Meal Correlation', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E0F2F1')),
                  children: [
                    _tableCell('Date & Time', isHeader: true),
                    _tableCell('Meal Context', isHeader: true),
                    _tableCell('Reading (mg/dL)', isHeader: true),
                    _tableCell('Status', isHeader: true),
                    _tableCell('Notes', isHeader: true),
                  ],
                ),
                ...readings.take(15).map((r) {
                  final val = r['reading_value']?.toString() ?? '0';
                  final meal = r['meal_type']?.toString() ?? 'Random';
                  final dt = r['display_date']?.toString() ?? '';
                  final status = (r['status'] ?? 'normal').toString().toUpperCase();
                  final notes = r['notes']?.toString() ?? '-';

                  return pw.TableRow(
                    children: [
                      _tableCell(dt),
                      _tableCell(meal),
                      _tableCell(val, isBold: true),
                      _tableCell(status),
                      _tableCell(notes),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Doctor's Assessment Section
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Physician / Diabetologist Clinical Assessment & Adjustments:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 35),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Physician Signature: _________________________', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Date: _______________', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Disclaimer
            pw.Text(
              'Confidential Healthcare Record. Generated via Diacare Diabetes Management Application. This report is intended solely for clinical review by the treating physician and dietitian to assist in ongoing care optimization.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Diacare_Report_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildMetricBox(String title, String value, String sub) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#00897B'))),
            pw.SizedBox(height: 2),
            pw.Text(sub, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

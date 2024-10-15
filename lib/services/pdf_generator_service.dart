import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  final pw.Document pdf = pw.Document();

 
  Future<Uint8List> generatePdf({
    required String operatorName,
    required String operatorAddress,
    required String eoriNumber,
    required String hsCode,
    required String description,
    required String tradeName,
    required String scientificName,
    required String quantity,
    required String country,
    required List<Map<String, dynamic>> plots,
    required String signatoryName,
    required String signatoryFunction,
    required String date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildTitle(),
          _buildOperatorInfo(operatorName, operatorAddress, eoriNumber),
          _buildProductInfo(
              hsCode, description, tradeName, scientificName, quantity),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildGeolocationInfo(country, plots),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildComplianceStatement(),
          _buildSignature(signatoryName, signatoryFunction, date),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTitle() {
    return pw.Header(
      level: 0,
      child: pw.Text('Due Diligence Statement',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _buildOperatorInfo(String name, String address, String eoriNumber) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: '1. Operator Information'),
        pw.Text('Name: $name'),
        pw.Text('Address: $address'),
        pw.Text('EORI Number: $eoriNumber'),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildProductInfo(String hsCode, String description,
      String tradeName, String scientificName, String quantity) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: '2. Product Information'),
        pw.Text('HS Code: $hsCode'),
        pw.Text('Description: $description'),
        pw.Text('Trade Name: $tradeName'),
        pw.Text('Scientific Name: $scientificName'),
        pw.Text('Quantity: $quantity'),
      ],
    );
  }

  pw.Widget _buildGeolocationInfo(
      String country, List<Map<String, dynamic>> plots) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: '3. Geolocation Information'),
        pw.Text('Country of Production: $country'),
        pw.Text('Deforestation risk is determind by WHISP (https://whisp.openforis.org/)'),
        pw.SizedBox(height: 10),
        pw.Text('Plots and Deforestation Risk:'),
        pw.TableHelper.fromTextArray(
          headers: ['Plot ID\ngeoID by AgStack https://agstack.github.io/agstack-website/)', 'Deforestation Risk'],
          data: plots
              .map((plot) => [
                    plot['geoid'].toString(),
                    plot['deforestation_risk'].toString()
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  pw.Widget _buildComplianceStatement() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: '4. Compliance Statement'),
        pw.Text(
          'By submitting this due diligence statement the operator confirms that due diligence in accordance with Regulation (EU) 2023/1115 was carried out and that no or only a negligible risk was found that the relevant products do not comply with Article 3, point (a) or (b), of that Regulation.',
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildSignature(String name, String function, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: '5. Signature'),
        pw.Text('Signed for and on behalf of:'),
        pw.SizedBox(height: 10),
        pw.Text('Date: $date'),
        pw.SizedBox(height: 10),
        pw.Text('Name and function: $name, $function'),
        pw.SizedBox(height: 30),
        pw.Container(
          width: 200,
          height: 1,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 5),
        pw.Text('Signature'),
      ],
    );
  }
}

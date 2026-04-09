import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);

  // --- REPORTE IMPOSITIVO Y DE LIQUIDEZ ---
  static Future<void> generarYMostrarReporteMensual({
    required DateTime fecha,
    required double saldoEnCaja,
    required double dineroEnLaCalle,
    required double deudaAProveedores,
    required double baseVentas,
    required double baseComprasLocal,
    required double ivaVentasTotal,
    required double ivaComprasLocal,
    required double ivaImportacionesMes,
    required double ivaComprasTotal,
    required double saldoIvaAnterior,
    required double saldoIvaFinal,
    required double itCalculado,
    required double iueCompensar,
    required double itPorPagarFinal,
    required double nuevoIueRestante,
  }) async {
    final pdf = pw.Document();
    final mesStr = DateFormat('MMMM yyyy', 'es_ES').format(fecha).toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(mesStr),
            pw.SizedBox(height: 20),
            
            _buildSeccionTitulo('1. ESTADO DE LIQUIDEZ Y CAJA'),
            _buildInfoRow('Saldo en Caja (Efectivo/Bancos):', _currencyFormat.format(saldoEnCaja), isBold: true),
            _buildInfoRow('Cuentas por Cobrar (Dinero en la calle):', _currencyFormat.format(dineroEnLaCalle)),
            _buildInfoRow('Cuentas por Pagar (Deudas a Proveedores):', _currencyFormat.format(deudaAProveedores), color: PdfColors.red700),
            pw.SizedBox(height: 20),

            _buildSeccionTitulo('2. MOVIMIENTO COMERCIAL FACTURADO'),
            _buildInfoRow('Total Ingresos Facturados (Base IVA Ventas):', _currencyFormat.format(baseVentas)),
            _buildInfoRow('Total Compras/Gastos Facturados (Base IVA Compras):', _currencyFormat.format(baseComprasLocal)),
            pw.SizedBox(height: 20),

            _buildSeccionTitulo('3. LIQUIDACIÓN DE IVA'),
            _buildInfoRow('Débito Fiscal (IVA a Pagar por Ventas):', _currencyFormat.format(ivaVentasTotal), color: PdfColors.red700),
            pw.Divider(thickness: 0.5),
            _buildInfoRow('Crédito Fiscal (Compras Locales):', _currencyFormat.format(ivaComprasLocal)),
            _buildInfoRow('Crédito Fiscal (Importaciones - Pólizas):', _currencyFormat.format(ivaImportacionesMes)),
            _buildInfoRow('Saldo IVA a Favor del Mes Anterior:', _currencyFormat.format(saldoIvaAnterior)),
            pw.Divider(thickness: 0.5),
            _buildInfoRow('Total Crédito Fiscal Disponible:', _currencyFormat.format(ivaComprasTotal)),
            pw.SizedBox(height: 10),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: saldoIvaFinal >= 0 ? PdfColors.green50 : PdfColors.red50,
              child: _buildInfoRow(
                saldoIvaFinal >= 0 ? 'NUEVO SALDO IVA A FAVOR:' : 'IVA DEFINITIVO A PAGAR:', 
                _currencyFormat.format(saldoIvaFinal.abs()),
                isBold: true,
                color: saldoIvaFinal >= 0 ? PdfColors.green800 : PdfColors.red800,
              ),
            ),
            pw.SizedBox(height: 20),

            _buildSeccionTitulo('4. LIQUIDACIÓN DE IT Y COMPENSACIÓN IUE'),
            _buildInfoRow('Impuesto a las Transacciones (IT) Calculado:', _currencyFormat.format(itCalculado)),
            _buildInfoRow('Saldo IUE Disponible para Compensar:', _currencyFormat.format(iueCompensar)),
            pw.SizedBox(height: 10),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.blue50,
              child: pw.Column(
                children: [
                  _buildInfoRow('IT DEFINITIVO A PAGAR (EFECTIVO):', _currencyFormat.format(itPorPagarFinal), isBold: true, color: PdfColors.blue800),
                  pw.SizedBox(height: 4),
                  _buildInfoRow('Nuevo Saldo IUE para el próximo mes:', _currencyFormat.format(nuevoIueRestante), color: PdfColors.grey700),
                ]
              )
            ),
            
            pw.SizedBox(height: 40),
            pw.Center(child: pw.Text('Reporte generado automáticamente por AMS Factory', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Mensual_$mesStr.pdf',
    );
  }

  // --- REPORTE CONSOLIDADO: LIBRO DE MOVIMIENTOS ---
  static Future<void> generarLibroMovimientos({
    required DateTime fecha,
    required List<dynamic> ventas,
    required List<dynamic> compras,
    required List<dynamic> ingresos,
    required List<dynamic> salidas,
    required List<dynamic> gastos,
  }) async {
    final pdf = pw.Document();
    final mesStr = DateFormat('MMMM yyyy', 'es_ES').format(fecha).toUpperCase();
    final fechaActual = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pw.Widget dibujarTablaConTitulo(String titulo, List<String> headers, List<List<String>> data, double total) {
      if (data.isEmpty) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSeccionTitulo(titulo),
            pw.Text('No hay movimientos registrados.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.SizedBox(height: 15),
          ],
        );
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSeccionTitulo(titulo),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            cellAlignments: {
              for (var i = 0; i < headers.length; i++) i: (i >= headers.length - 2) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            },
          ),
          pw.SizedBox(height: 5),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('TOTAL $titulo: ${_currencyFormat.format(total)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(mesStr),
            pw.Text('Generado el: $fechaActual', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),

            // 1. VENTAS
            dibujarTablaConTitulo(
              'VENTAS REALIZADAS',
              ['Fecha', 'Cliente', 'Producto/Parte', 'Cant.', 'Precio', 'Subtotal', 'Fac.'],
              ventas.map<List<String>>((v) => [
                DateFormat('dd/MM/yyyy').format(v.fecha),
                v.cliente?.toString() ?? '-',
                v.parteNombre?.toString() ?? '-',
                v.cantidad?.toString() ?? '0',
                (v.precio ?? 0).toStringAsFixed(2),
                ((v.precio ?? 0) * (v.cantidad ?? 0)).toStringAsFixed(2),
                (v.facturado ?? false) ? 'Sí' : 'No'
              ]).toList(),
              ventas.fold(0.0, (sum, v) => sum + ((v.precio ?? 0) * (v.cantidad ?? 0))),
            ),

            // 2. INGRESOS
            dibujarTablaConTitulo(
              'OTROS INGRESOS DE CAJA',
              ['Fecha', 'Detalle', 'Descripción', 'Método', 'Monto', 'Fac.'],
              ingresos.map<List<String>>((i) => [
                DateFormat('dd/MM/yyyy').format(i.fecha),
                i.detalle?.toString() ?? '-',
                i.descripcion?.toString() ?? '-',
                i.metodoPago?.toString() ?? '-',
                (i.precio ?? 0).toStringAsFixed(2),
                (i.facturado ?? false) ? 'Sí' : 'No'
              ]).toList(),
              ingresos.fold(0.0, (sum, i) => sum + (i.precio ?? 0)),
            ),

            // 3. COMPRAS
            dibujarTablaConTitulo(
              'COMPRAS LOCALES (INVENTARIO)',
              ['Fecha', 'Proveedor', 'Producto/Parte', 'Cant.', 'Precio', 'Subtotal', 'Fac.'],
              compras.map<List<String>>((c) => [
                DateFormat('dd/MM/yyyy').format(c.fecha),
                c.proveedor?.toString() ?? '-',
                c.parteNombre?.toString() ?? '-',
                c.cantidad?.toString() ?? '0',
                (c.precio ?? 0).toStringAsFixed(2),
                ((c.precio ?? 0) * (c.cantidad ?? 0)).toStringAsFixed(2),
                (c.facturado ?? false) ? 'Sí' : 'No'
              ]).toList(),
              compras.fold(0.0, (sum, c) => sum + ((c.precio ?? 0) * (c.cantidad ?? 0))),
            ),

            // 4. GASTOS (Ajustado a g.tipo)
            dibujarTablaConTitulo(
              'GASTOS OPERATIVOS',
              ['Fecha', 'Tipo de Gasto', 'Descripción', 'Monto', 'Fac.'], // <-- Se eliminó "Método"
              gastos.map<List<String>>((g) => [
                DateFormat('dd/MM/yyyy').format(g.fecha),
                g.tipo?.toString() ?? '-',                        // <-- Usa g.tipo
                g.descripcion?.toString() ?? '-',
                (g.monto ?? 0).toStringAsFixed(2),
                (g.facturado ?? false) ? 'Sí' : 'No'
              ]).toList(),
              gastos.fold(0.0, (sum, g) => sum + (g.monto ?? 0)),
            ),

            // 5. SALIDAS
            dibujarTablaConTitulo(
              'OTRAS SALIDAS DE CAJA (Pagos)',
              ['Fecha', 'Detalle', 'Descripción', 'Método', 'Monto', 'Fac.'],
              salidas.map<List<String>>((s) => [
                DateFormat('dd/MM/yyyy').format(s.fecha),
                s.detalle?.toString() ?? '-',
                s.descripcion?.toString() ?? '-',
                s.metodoPago?.toString() ?? '-',
                (s.precio ?? 0).toStringAsFixed(2),
                (s.facturado ?? false) ? 'Sí' : 'No'
              ]).toList(),
              salidas.fold(0.0, (sum, s) => sum + (s.precio ?? 0)),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Libro_Movimientos_$mesStr.pdf',
    );
  }

  // --- WIDGETS AUXILIARES ---
  static pw.Widget _buildHeader(String mes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('REPORTE FINANCIERO E IMPOSITIVO', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.Text('AMS FACTORY - PERIODO: $mes', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
      ],
    );
  }

  static pw.Widget _buildSeccionTitulo(String titulo) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(titulo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }
}
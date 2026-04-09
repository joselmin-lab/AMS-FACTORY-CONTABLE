import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class ImportacionesService extends ChangeNotifier {
  List<ImpCarpeta> _carpetas = [];
  bool _isLoading = false;
  String? _error;

  List<ImpCarpeta> get carpetas => List.unmodifiable(_carpetas);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double ivaVentasLocal = 14.94;

  Future<void> fetchCarpetas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await SupabaseService.client
          .from('imp_carpetas')
          .select('*, imp_items(*), imp_gastos(*), imp_pagos(*)')
          .order('fecha_apertura', ascending: false);
      _carpetas = (response as List).map((e) => ImpCarpeta.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 1. APERTURA CON GASTOS AUTOMÁTICOS ---
  Future<bool> crearCarpeta(ImpCarpeta carpeta) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await SupabaseService.client.from('imp_carpetas').insert(carpeta.toJson()).select().single();
      final String nuevaCarpetaId = res['id'];

      // Inyectar los 6 gastos del sistema
      final gastosBase = [
        ImpGasto(proveedor: 'Naviera / Courier', descripcion: 'Flete Internacional', moneda: 'USD', montoOriginal: carpeta.fleteEstimadoUsd, tipoCambio: carpeta.tipoCambio, montoBs: carpeta.fleteEstimadoUsd * carpeta.tipoCambio, esCapitalizable: true, fechaGasto: DateTime.now(), tipoSistema: 'FLETE'),
        ImpGasto(proveedor: 'Aduana Nacional', descripcion: 'Arancel (GA)', moneda: 'Bs', montoOriginal: 0, tipoCambio: 1, montoBs: 0, esCapitalizable: true, fechaGasto: DateTime.now(), tipoSistema: 'GA'),
        ImpGasto(proveedor: 'Aduana Nacional', descripcion: 'IVA Importación', moneda: 'Bs', montoOriginal: 0, tipoCambio: 1, montoBs: 0, esCapitalizable: true, tieneIva: true, fechaGasto: DateTime.now(), tipoSistema: 'IVA'),
        ImpGasto(proveedor: 'Agencia Despachante', descripcion: 'Honorarios Despachante', moneda: 'Bs', montoOriginal: carpeta.despachanteEstimadoBs, tipoCambio: 1, montoBs: carpeta.despachanteEstimadoBs, esCapitalizable: true, fechaGasto: DateTime.now(), tipoSistema: 'DESPACHANTE'),
        ImpGasto(proveedor: 'Aduana / ASPB', descripcion: 'Documentación', moneda: 'Bs', montoOriginal: carpeta.documentacionEstimadaBs, tipoCambio: 1, montoBs: carpeta.documentacionEstimadaBs, esCapitalizable: true, fechaGasto: DateTime.now(), tipoSistema: 'DOCUMENTACION'),
        ImpGasto(proveedor: 'Almacén Aduanero', descripcion: 'Almacenaje', moneda: 'Bs', montoOriginal: carpeta.almacenajeEstimadoBs, tipoCambio: 1, montoBs: carpeta.almacenajeEstimadoBs, esCapitalizable: true, fechaGasto: DateTime.now(), tipoSistema: 'ALMACENAJE'),
      ];

      for (var g in gastosBase) {
        final gMap = g.toJson();
        gMap['carpeta_id'] = nuevaCarpetaId;
        await SupabaseService.client.from('imp_gastos').insert(gMap);
      }

      await fetchCarpetas();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- 2. RECALCULAR IMPUESTOS AL MODIFICAR ÍTEMS ---
  Future<void> recalcularImpuestosAutomaticos(String carpetaId) async {
    try {
      final response = await SupabaseService.client.from('imp_carpetas').select('*, imp_items(*), imp_gastos(*)').eq('id', carpetaId).single();
      final carpeta = ImpCarpeta.fromJson(response);

      double totalGaBs = 0;
      double totalIvaBs = 0;

      for (var item in carpeta.items) {
        totalGaBs += item.totalGaBs(carpeta.tipoCambio, carpeta.porcentajeDeclaracion);
        totalIvaBs += item.totalIvaBs(carpeta.tipoCambio, carpeta.porcentajeDeclaracion);
      }

      // Actualizar los gastos GA e IVA
      final gastoGa = carpeta.gastos.firstWhere((g) => g.tipoSistema == 'GA');
      final gastoIva = carpeta.gastos.firstWhere((g) => g.tipoSistema == 'IVA');

      await SupabaseService.client.from('imp_gastos').update({'monto_original': totalGaBs, 'monto_bs': totalGaBs}).eq('id', gastoGa.id!);
      await SupabaseService.client.from('imp_gastos').update({'monto_original': totalIvaBs, 'monto_bs': totalIvaBs}).eq('id', gastoIva.id!);

      await fetchCarpetas();
    } catch (e) {
      debugPrint('Error recalculando impuestos: $e');
    }
  }

  Future<bool> eliminarCarpeta(String carpetaId) async {
    try {
      final pagos = await SupabaseService.client.from('imp_pagos').select('salida_id').eq('carpeta_id', carpetaId);
      for (var p in pagos) {
        if (p['salida_id'] != null) await SupabaseService.client.from('salidas_contable').delete().eq('id', p['salida_id']);
      }
      await SupabaseService.client.from('imp_carpetas').delete().eq('id', carpetaId);
      await fetchCarpetas();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> guardarGasto(String carpetaId, ImpGasto gasto) async {
    try {
      final mapa = gasto.toJson();
      if (gasto.id == null) {
        mapa['carpeta_id'] = carpetaId;
        await SupabaseService.client.from('imp_gastos').insert(mapa);
      } else {
        await SupabaseService.client.from('imp_gastos').update(mapa).eq('id', gasto.id!);
      }
      await fetchCarpetas();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarGasto(String gastoId) async {
    try {
      await SupabaseService.client.from('imp_gastos').delete().eq('id', gastoId);
      await fetchCarpetas();
      return true;
    } catch (e) {
      return false;
    }
  }

    Future<bool> agregarPago(String carpetaId, ImpCarpeta carpeta, ImpPago pago) async {
    try {
      final salidaRes = await SupabaseService.client.from('salidas_contable').insert({
        'detalle': pago.concepto, // La UI ya enviará el texto automático aquí
        'precio': pago.montoBs,
        'fecha': pago.fecha.toIso8601String(),
        'metodo_pago': 'Transferencia Bancaria', // Campo obligatorio que faltaba
        'facturado': false, // Campo obligatorio que faltaba
      }).select().single();

      final mapaPago = pago.toJson();
      mapaPago['carpeta_id'] = carpetaId;
      mapaPago['salida_id'] = salidaRes['id'];
      
      await SupabaseService.client.from('imp_pagos').insert(mapaPago);
      await fetchCarpetas();
      return true;
    } catch (e) {
      _error = e.toString(); // ¡Aquí capturamos el error real!
      notifyListeners();
      return false;
    }
  }

  Future<bool> liquidarCarpeta(String carpetaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final carpeta = _carpetas.firstWhere((c) => c.id == carpetaId);
      final double totalFobUsd = carpeta.items.fold(0, (sum, item) => sum + item.totalFobUsd);
      final double totalFobBs = totalFobUsd * carpeta.tipoCambio;
      final double pesoTotal = carpeta.items.fold(0, (sum, item) => sum + item.pesoTotal);
      final double cantidadTotal = carpeta.items.fold(0, (sum, item) => sum + item.cantidad);

      double gastosValorBs = 0, gastosPesoBs = 0, gastosCantBs = 0, totalGastosCapBs = 0;

      for (var gasto in carpeta.gastos) {
        if (gasto.esCapitalizable) {
          double costoRealBs = gasto.tieneIva ? gasto.montoBs * (1 - (ivaVentasLocal / 100)) : gasto.montoBs;
          totalGastosCapBs += costoRealBs;
          switch (gasto.metodoProrrateo) {
            case 'Valor': gastosValorBs += costoRealBs; break;
            case 'Peso': gastosPesoBs += costoRealBs; break;
            case 'Cantidad': gastosCantBs += costoRealBs; break;
          }
        }
      }

      for (var item in carpeta.items) {
        final double itemFobBs = item.totalFobUsd * carpeta.tipoCambio;
        final double pValor = totalFobBs > 0 ? (itemFobBs / totalFobBs) : 0;
        final double pPeso = pesoTotal > 0 ? (item.pesoTotal / pesoTotal) : 0;
        final double pCant = cantidadTotal > 0 ? (item.cantidad / cantidadTotal) : 0;

        final double gastoAsignado = (gastosValorBs * pValor) + (gastosPesoBs * pPeso) + (gastosCantBs * pCant);
        final double costoUnitarioBs = item.cantidad > 0 ? ((itemFobBs + gastoAsignado) / item.cantidad) : 0;

        await SupabaseService.client.from('imp_items').update({'factor_prorrateo': pValor, 'costo_unitario_bs': costoUnitarioBs}).eq('id', item.id!);

        if (item.inventarioId != null) {
          try {
            final invRes = await SupabaseService.client.from('inventario').select('stock_actual').eq('id', item.inventarioId!).maybeSingle();
            if (invRes != null) {
              await SupabaseService.client.from('inventario').update({'stock_actual': ((invRes['stock_actual'] as num?)?.toDouble() ?? 0) + item.cantidad}).eq('id', item.inventarioId!);
            }
          } catch(e) { debugPrint(e.toString()); }
        }
      }

      // Cuentas por Pagar Automáticas
      final pagosFobBs = carpeta.pagos.where((p) => p.gastoId == null).fold(0.0, (sum, p) => sum + p.montoBs);
      if (totalFobBs > pagosFobBs) {
        await SupabaseService.client.from('cuentas_pagar').insert({'proveedor': carpeta.proveedor, 'detalle': 'Saldo Imp. [${carpeta.numeroDespacho}]', 'monto_total': totalFobBs - pagosFobBs, 'monto_pagado': 0, 'estado': 'pendiente', 'importacion_id': carpeta.id});
      }

      for (var gasto in carpeta.gastos) {
        final pagosGasto = carpeta.pagos.where((p) => p.gastoId == gasto.id).fold(0.0, (sum, p) => sum + p.montoBs);
        if (gasto.montoBs > pagosGasto) {
          await SupabaseService.client.from('cuentas_pagar').insert({'proveedor': gasto.proveedor, 'detalle': 'Gasto Imp. [${carpeta.numeroDespacho}]: ${gasto.descripcion}', 'monto_total': gasto.montoBs - pagosGasto, 'monto_pagado': 0, 'estado': 'pendiente', 'importacion_id': carpeta.id, 'gasto_imp_id': gasto.id});
        }
      }

      await SupabaseService.client.from('imp_carpetas').update({'estado': 'Liquidada', 'fecha_cierre': DateTime.now().toIso8601String(), 'total_fob_usd': totalFobUsd, 'total_gastos_bs': totalGastosCapBs, 'costo_total_bs': totalFobBs + totalGastosCapBs}).eq('id', carpeta.id!);
      await fetchCarpetas();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
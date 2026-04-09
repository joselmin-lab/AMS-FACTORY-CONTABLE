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

  double ivaVentasLocal = 14.94; // Referencia impositiva

  Future<void> fetchCarpetas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ahora también traemos los pagos vinculados a la carpeta
      final response = await SupabaseService.client
          .from('imp_carpetas')
          .select('*, imp_items(*), imp_gastos(*), imp_pagos(*)')
          .order('fecha_apertura', ascending: false);

      _carpetas = (response as List)
          .map((e) => ImpCarpeta.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 1. APERTURA DE CARPETA ---
  Future<bool> crearCarpeta(ImpCarpeta carpeta) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.client
          .from('imp_carpetas')
          .insert(carpeta.toJson());

      await fetchCarpetas();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- 2. ELIMINAR CARPETA ---
  Future<bool> eliminarCarpeta(String carpetaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Antes de borrar la carpeta, buscamos si hay Pagos que hayan generado salidas en Caja
      final pagos = await SupabaseService.client
          .from('imp_pagos')
          .select('salida_id')
          .eq('carpeta_id', carpetaId);

      // 2. Borramos las salidas de caja (para devolver el dinero al sistema)
      for (var p in pagos) {
        if (p['salida_id'] != null) {
          await SupabaseService.client
              .from('salidas_contable')
              .delete()
              .eq('id', p['salida_id']);
        }
      }

      // 3. Borramos la carpeta (Supabase borrará automáticamente ítems y gastos por el CASCADE)
      await SupabaseService.client.from('imp_carpetas').delete().eq('id', carpetaId);
      
      await fetchCarpetas();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- 3. AGREGAR GASTOS OPERATIVOS ---
  Future<bool> agregarGasto(String carpetaId, ImpGasto gasto) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final mapa = gasto.toJson();
      mapa['carpeta_id'] = carpetaId;
      await SupabaseService.client.from('imp_gastos').insert(mapa);
      await fetchCarpetas();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- 4. REGISTRAR PAGOS (ANTICIPOS) Y ENVIAR A CAJA ---
  Future<bool> agregarPago(String carpetaId, ImpCarpeta carpeta, ImpPago pago) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Insertamos el pago en la tabla salidas_contable para descontar de tu Caja Físicamente
      final salidaRes = await SupabaseService.client.from('salidas_contable').insert({
        'detalle': 'Pago Importación [${carpeta.numeroDespacho}]: ${pago.concepto}',
        'precio': pago.montoBs,
        'fecha': pago.fecha.toIso8601String(),
      }).select().single();

      final salidaId = salidaRes['id'] as String;

      // 2. Insertamos el registro en la carpeta de importación
      final mapaPago = pago.toJson();
      mapaPago['carpeta_id'] = carpetaId;
      mapaPago['salida_id'] = salidaId; // Guardamos el rastro de la salida
      
      await SupabaseService.client.from('imp_pagos').insert(mapaPago);
      await fetchCarpetas();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- 5. LIQUIDAR CARPETA (Motor de Prorrateo de Costos) ---
  Future<bool> liquidarCarpeta(String carpetaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final carpeta = _carpetas.firstWhere((c) => c.id == carpetaId);
      
      final double totalFobUsd = carpeta.items.fold(0, (sum, item) => sum + item.totalFobUsd);
      final double totalFobBs = totalFobUsd * carpeta.tipoCambio;
      final double pesoTotal = carpeta.items.fold(0, (sum, item) => sum + item.pesoTotal);
      final double cantidadTotal = carpeta.items.fold(0, (sum, item) => sum + item.cantidad);

      double gastosPorValorBs = 0;
      double gastosPorPesoBs = 0;
      double gastosPorCantidadBs = 0;
      double totalGastosCapitalizadosBs = 0;

      for (var gasto in carpeta.gastos) {
        if (gasto.esCapitalizable) {
          double costoRealBs = gasto.tieneIva ? gasto.montoBs * (1 - (ivaVentasLocal / 100)) : gasto.montoBs;
          totalGastosCapitalizadosBs += costoRealBs;

          switch (gasto.metodoProrrateo) {
            case 'Valor': gastosPorValorBs += costoRealBs; break;
            case 'Peso': gastosPorPesoBs += costoRealBs; break;
            case 'Cantidad': gastosPorCantidadBs += costoRealBs; break;
          }
        }
      }

      final double costoTotalCarpetaBs = totalFobBs + totalGastosCapitalizadosBs;

      for (var item in carpeta.items) {
        final double itemFobBs = item.totalFobUsd * carpeta.tipoCambio;
        
        final double participacionValor = totalFobBs > 0 ? (itemFobBs / totalFobBs) : 0;
        final double participacionPeso = pesoTotal > 0 ? (item.pesoTotal / pesoTotal) : 0;
        final double participacionCantidad = cantidadTotal > 0 ? (item.cantidad / cantidadTotal) : 0;

        final double gastoAsignado = 
            (gastosPorValorBs * participacionValor) + 
            (gastosPorPesoBs * participacionPeso) + 
            (gastosPorCantidadBs * participacionCantidad);

        final double costoTotalItemBs = itemFobBs + gastoAsignado;
        final double costoUnitarioBs = item.cantidad > 0 ? (costoTotalItemBs / item.cantidad) : 0;

        await SupabaseService.client
            .from('imp_items')
            .update({
              'factor_prorrateo': participacionValor,
              'costo_unitario_bs': costoUnitarioBs
            })
            .eq('id', item.id!);
      }

      await SupabaseService.client
          .from('imp_carpetas')
          .update({
            'estado': 'Liquidada',
            'fecha_cierre': DateTime.now().toIso8601String(),
            'total_fob_usd': totalFobUsd,
            'total_gastos_bs': totalGastosCapitalizadosBs,
            'costo_total_bs': costoTotalCarpetaBs,
          })
          .eq('id', carpeta.id!);

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
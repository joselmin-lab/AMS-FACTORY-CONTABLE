import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/cuenta_pagar.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class CuentasPagarService extends ChangeNotifier {
  List<CuentaPagar> _cuentas = [];
  bool _isLoading = false;
  String? _error;

  List<CuentaPagar> get cuentas => List.unmodifiable(_cuentas);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'cuentas_pagar';

  Future<void> fetchCuentas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await SupabaseService.client
          .from(_table)
          .select()
          .order('fecha_emision', ascending: false);
      _cuentas = (response as List)
          .map((e) => CuentaPagar.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCuenta(CuentaPagar cuenta) async {
    try {
      await SupabaseService.client.from(_table).insert(cuenta.toJson());
      await fetchCuentas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCuenta(CuentaPagar cuenta) async {
    try {
      await SupabaseService.client.from(_table).update(cuenta.toJson()).eq('id', cuenta.id!);
      await fetchCuentas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCuenta(String id) async {
    try {
      await SupabaseService.client.from(_table).delete().eq('id', id);
      _cuentas.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- REGISTRO DE PAGO MULTIMONEDA ---
  Future<bool> registrarPago(String id, double montoAbono, String metodoPago, {double tcCaja = 1.0}) async {
    try {
      final cuenta = _cuentas.firstWhere((c) => c.id == id);
      
      final nuevoMontoPagado = cuenta.montoPagado + montoAbono;
      String nuevoEstado = 'parcial';
      // Con una pequeñísima tolerancia para redondeos flotantes
      if (nuevoMontoPagado >= (cuenta.montoTotal - 0.01)) {
        nuevoEstado = 'pagado';
      }

      // 1. Actualizamos la deuda (El monto abonado está en la moneda original de la deuda)
      await SupabaseService.client.from(_table).update({
        'monto_pagado': nuevoMontoPagado,
        'estado': nuevoEstado,
      }).eq('id', id);

      // 2. Registramos la Salida de Caja (Siempre en Bolivianos)
      // Si la deuda era en USD, multiplicamos el abono por el TC del día
      final montoParaCajaBs = cuenta.moneda == 'USD' ? (montoAbono * tcCaja) : montoAbono;
      
      String detallePago = 'Pago a proveedor: ${cuenta.proveedor}';
      if (cuenta.moneda == 'USD') {
        detallePago += ' (\$US $montoAbono pagados a TC $tcCaja)';
      }

      await SupabaseService.client.from('salidas_contable').insert({
        'detalle': detallePago,
        'descripcion': 'Pago de Cuenta por Pagar',
        'precio': montoParaCajaBs,
        'metodo_pago': metodoPago,
        'facturado': false,
        'fecha': DateTime.now().toIso8601String(),
        'usuario_id': SupabaseService.client.auth.currentUser?.id,
      });

      await fetchCuentas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
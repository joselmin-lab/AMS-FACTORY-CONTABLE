import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/cuenta_pagar.dart';
import 'package:ams_control_contable/services/supabase_service.dart';
import 'package:ams_control_contable/models/cuenta_cobrar.dart'; // Para obtener el enum EstadoCuenta

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
      await SupabaseService.client
          .from(_table)
          .update(cuenta.toJson())
          .eq('id', cuenta.id!);
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

  // Método para registrar el pago y crear el egreso en caja
  Future<bool> registrarPago(String id, double montoAbono, String metodoPago) async {
    try {
      final cuenta = _cuentas.firstWhere((c) => c.id == id);
      
      final nuevoMontoPagado = cuenta.montoPagado + montoAbono;
      String nuevoEstado = 'parcial';
      if (nuevoMontoPagado >= cuenta.montoTotal) {
        nuevoEstado = 'pagado';
      }

      // 1. Actualizamos la deuda
      await SupabaseService.client.from(_table).update({
        'monto_pagado': nuevoMontoPagado,
        'estado': nuevoEstado,
      }).eq('id', id);

      // 2. REGISTRAMOS LA SALIDA DE DINERO A CAJA (En la tabla salidas_contable)
      await SupabaseService.client.from('salidas_contable').insert({
        'detalle': 'Pago a proveedor: ${cuenta.proveedor}',
        'descripcion': 'Abono de deuda por compras',
        'precio': montoAbono,
        'metodo_pago': metodoPago,
        'facturado': false,
        'fecha': DateTime.now().toIso8601String(),
      });

      await fetchCuentas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  double get totalPendiente => _cuentas
      .where((c) => c.estado != EstadoCuenta.pagado)
      .fold(0, (sum, c) => sum + c.saldoPendiente);
}
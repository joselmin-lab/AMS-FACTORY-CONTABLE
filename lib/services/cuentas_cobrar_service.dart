import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/cuenta_cobrar.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class CuentasCobrarService extends ChangeNotifier {
  List<CuentaCobrar> _cuentas = [];
  bool _isLoading = false;
  String? _error;

  List<CuentaCobrar> get cuentas => List.unmodifiable(_cuentas);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'cuentas_cobrar';

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
          .map((e) => CuentaCobrar.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCuenta(CuentaCobrar cuenta) async {
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

  Future<bool> updateCuenta(CuentaCobrar cuenta) async {
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

  // Método para registrar un pago a una cuenta existente y guardarlo en caja
  Future<bool> registrarPago(String id, double montoAbono, String metodoPago) async {
    try {
      // 1. Buscamos la cuenta actual en la lista local
      final cuenta = _cuentas.firstWhere((c) => c.id == id);
      
      // 2. Sumamos el nuevo abono a lo que ya estaba pagado
      final nuevoMontoPagado = cuenta.montoPagado + montoAbono;
      
      // 3. Determinamos el nuevo estado
      String nuevoEstado = 'parcial';
      if (nuevoMontoPagado >= cuenta.montoTotal) {
        nuevoEstado = 'pagado';
      }

      // 4. Actualizamos la deuda en Supabase
      await SupabaseService.client.from(_table).update({
        'monto_pagado': nuevoMontoPagado,
        'estado': nuevoEstado,
      }).eq('id', id);

      // 5. REGISTRAMOS EL INGRESO DE DINERO A CAJA (Nueva tabla)
      await SupabaseService.client.from('ingresos_contable').insert({
        'detalle': 'Abono de deuda: ${cuenta.cliente}',
        'monto': montoAbono,
        'metodo_pago': metodoPago,
        'referencia_id': id,
        'fecha': DateTime.now().toIso8601String(),
      });

      // 6. Recargamos la lista para que la interfaz se actualice
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
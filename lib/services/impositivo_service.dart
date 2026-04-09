import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/tax_config.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class ImpositivoService extends ChangeNotifier {
  TaxConfig _config = TaxConfig.defaults();
  bool _isLoading = false;
  String? _error;

  TaxConfig get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'configuracion_impositiva';

  Future<void> fetchConfig() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.from(_table).select().limit(1).single();
      _config = TaxConfig.fromJson(response);
    } catch (e) {
      _error = 'Error al cargar impuestos. Usando valores por defecto.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateConfig(TaxConfig nuevaConfig) async {
    try {
      final response = await SupabaseService.client.from(_table).select('id').limit(1).single();
      final id = response['id'];

      await SupabaseService.client.from(_table).update({
        'iva_ventas': nuevaConfig.ivaVentas,
        'it_ventas': nuevaConfig.itVentas,
        'iva_compras': nuevaConfig.ivaCompras,
        'iue_utilidades': nuevaConfig.iueUtilidades,
        'saldo_iva_anterior': nuevaConfig.saldoIvaAnterior,
        'saldo_iue_compensar': nuevaConfig.saldoIuePorCompensar,
        'mes_cierre_gestion': nuevaConfig.mesCierreGestion,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      
      _config = nuevaConfig;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> actualizarSaldosArrastrados(double nuevoSaldoIva, double nuevoSaldoIue) async {
    try {
      final nuevaConfig = _config.copyWith(
        saldoIvaAnterior: nuevoSaldoIva,
        saldoIuePorCompensar: nuevoSaldoIue,
      );
      await updateConfig(nuevaConfig);
    } catch (e) {
      debugPrint('Error actualizando saldos arrastrados: $e');
    }
  }
}
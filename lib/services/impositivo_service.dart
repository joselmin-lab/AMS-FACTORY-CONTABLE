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
      // Si falla (ej. tabla vacía), mantenemos los defaults de Bolivia.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateConfig(TaxConfig nuevaConfig) async {
    try {
      // Como solo hay 1 registro, buscamos el primero que haya y lo actualizamos
      final response = await SupabaseService.client.from(_table).select('id').limit(1).single();
      final id = response['id'];

      await SupabaseService.client.from(_table).update({
        'iva_ventas': nuevaConfig.ivaVentas,
        'it_ventas': nuevaConfig.itVentas,
        'iva_compras': nuevaConfig.ivaCompras,
        'iue_utilidades': nuevaConfig.iueUtilidades,
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
}
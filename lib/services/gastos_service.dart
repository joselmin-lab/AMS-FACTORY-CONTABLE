import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/gasto.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class GastosService extends ChangeNotifier {
  List<Gasto> _gastos = [];
  bool _isLoading = false;
  String? _error;

  List<Gasto> get gastos => List.unmodifiable(_gastos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'gastos_contable';

  Future<void> fetchGastos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // MAGIA AQUÍ: Le pedimos a Supabase que genere los gastos fijos/variables/sueldos del mes actual si faltan
      await SupabaseService.client.rpc('generar_gastos_mensuales');

      // Luego procedemos a cargar la lista de plantillas de gastos
      final response = await SupabaseService.client
          .from(_table)
          .select()
          .order('fecha', ascending: false);
          
      _gastos = (response as List)
          .map((e) => Gasto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGasto(Gasto gasto) async {
    try {
      await SupabaseService.client.from(_table).insert(gasto.toJson());
      await fetchGastos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGasto(Gasto gasto) async {
    try {
      await SupabaseService.client
          .from(_table)
          .update(gasto.toJson())
          .eq('id', gasto.id!);
      await fetchGastos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGasto(String id) async {
    try {
      await SupabaseService.client.from(_table).delete().eq('id', id);
      _gastos.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Gasto> getGastosByTipo(TipoGasto tipo) {
    return _gastos.where((g) => g.tipo == tipo).toList();
  }

  double getTotalByTipo(TipoGasto tipo) {
    return getGastosByTipo(tipo).fold(0, (sum, g) => sum + g.monto);
  }
}
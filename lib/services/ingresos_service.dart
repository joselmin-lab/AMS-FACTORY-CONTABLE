import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/ingreso.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class IngresosService extends ChangeNotifier {
  List<Ingreso> _ingresos = [];
  bool _isLoading = false;
  String? _error;

  List<Ingreso> get ingresos => List.unmodifiable(_ingresos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'ingresos_contable';

  Future<void> fetchIngresos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from(_table)
          .select()
          .order('fecha', ascending: false);
      _ingresos = (response as List)
          .map((e) => Ingreso.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createIngreso(Ingreso ingreso) async {
    try {
      await SupabaseService.client.from(_table).insert(ingreso.toJson());
      await fetchIngresos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
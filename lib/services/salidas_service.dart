import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/salida.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class SalidasService extends ChangeNotifier {
  List<Salida> _salidas = [];
  bool _isLoading = false;
  String? _error;

  List<Salida> get salidas => List.unmodifiable(_salidas);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'salidas_contable';

  Future<void> fetchSalidas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from(_table)
          .select()
          .order('fecha', ascending: false);
      _salidas = (response as List)
          .map((e) => Salida.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSalida(Salida salida) async {
    try {
      await SupabaseService.client.from(_table).insert(salida.toJson());
      await fetchSalidas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSalida(String id) async {
    try {
      await SupabaseService.client.from(_table).delete().eq('id', id);
      _salidas.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  double get totalSalidas => _salidas.fold(0, (sum, s) => sum + s.precio);
}
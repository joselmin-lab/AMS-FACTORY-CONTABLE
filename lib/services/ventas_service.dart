import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/venta.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class VentasService extends ChangeNotifier {
  List<Venta> _ventas = [];
  bool _isLoading = false;
  String? _error;

  List<Venta> get ventas => List.unmodifiable(_ventas);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'ventas_contable';

  Future<void> fetchVentas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from(_table)
          .select()
          .order('fecha', ascending: false);
      _ventas = (response as List)
          .map((e) => Venta.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createVenta(Venta venta) async {
    try {
      await SupabaseService.client.from(_table).insert(venta.toJson());
      await fetchVentas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVenta(Venta venta) async {
    try {
      await SupabaseService.client
          .from(_table)
          .update(venta.toJson())
          .eq('id', venta.id!);
      await fetchVentas();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVenta(String id) async {
    try {
      await SupabaseService.client.from(_table).delete().eq('id', id);
      _ventas.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  double get totalVentas =>
      _ventas.fold(0, (sum, v) => sum + v.total);
}

import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/compra.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class ComprasService extends ChangeNotifier {
  List<Compra> _compras = [];
  bool _isLoading = false;
  String? _error;

  List<Compra> get compras => List.unmodifiable(_compras);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'compras_contable';

  Future<void> fetchCompras() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from(_table)
          .select()
          .order('fecha', ascending: false);
      _compras = (response as List)
          .map((e) => Compra.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCompra(Compra compra) async {
    try {
      await SupabaseService.client
          .from(_table)
          .insert(compra.toJson());
      await fetchCompras();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCompra(Compra compra) async {
    try {
      await SupabaseService.client
          .from(_table)
          .update(compra.toJson())
          .eq('id', compra.id!);
      await fetchCompras();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCompra(String id) async {
    try {
      await SupabaseService.client
          .from(_table)
          .delete()
          .eq('id', id);
      _compras.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  double get totalCompras =>
      _compras.fold(0, (sum, c) => sum + c.total);
}

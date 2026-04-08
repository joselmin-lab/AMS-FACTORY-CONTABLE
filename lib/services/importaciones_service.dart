import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class ImportacionesService extends ChangeNotifier {
  List<Importacion> _importaciones = [];
  bool _isLoading = false;
  String? _error;

  List<Importacion> get importaciones =>
      List.unmodifiable(_importaciones);
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _table = 'importaciones';

  Future<void> fetchImportaciones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from(_table)
          .select()
          .order('fecha', ascending: false);
      _importaciones = (response as List)
          .map((e) =>
              Importacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createImportacion(Importacion importacion) async {
    try {
      await SupabaseService.client
          .from(_table)
          .insert(importacion.toJson());
      await fetchImportaciones();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateImportacion(Importacion importacion) async {
    try {
      await SupabaseService.client
          .from(_table)
          .update(importacion.toJson())
          .eq('id', importacion.id!);
      await fetchImportaciones();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImportacion(String id) async {
    try {
      await SupabaseService.client
          .from(_table)
          .delete()
          .eq('id', id);
      _importaciones.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/cliente.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class ClientesService extends ChangeNotifier {
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String _table = 'clientes';

  Future<void> fetchClientes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseService.client.from(_table).select().order('nombre', ascending: true);
      _clientes = (response as List).map((e) => Cliente.fromJson(e)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCliente(Cliente cliente) async {
    try {
      await SupabaseService.client.from(_table).insert(cliente.toJson());
      await fetchClientes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCliente(Cliente cliente) async {
    try {
      await SupabaseService.client.from(_table).update(cliente.toJson()).eq('id', cliente.id!);
      await fetchClientes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCliente(String id) async {
    try {
      await SupabaseService.client.from(_table).delete().eq('id', id);
      _clientes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se puede eliminar: El cliente tiene registros asociados.';
      notifyListeners();
      return false;
    }
  }
}
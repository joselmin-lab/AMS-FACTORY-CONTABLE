import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/models/usuario.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class UsuariosService extends ChangeNotifier {
  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  List<Usuario> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsuarios() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseService.client.from('vw_usuarios').select().order('created_at', ascending: false);
      _usuarios = (response as List).map((e) => Usuario.fromJson(e)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUsuario(String email, String password, String nombre, String telefono) async {
    try {
      await SupabaseService.client.rpc('crear_usuario_admin', params: {
        'email_input': email,
        'password_input': password,
        'nombre_input': nombre,
        'telefono_input': telefono.isNotEmpty ? telefono : null,
      });
      await fetchUsuarios();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUsuario(String id) async {
    try {
      await SupabaseService.client.rpc('eliminar_usuario', params: {'uid': id});
      _usuarios.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String id, String nuevaPassword) async {
    try {
      await SupabaseService.client.rpc('actualizar_password_admin', params: {
        'uid': id,
        'new_password': nuevaPassword,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
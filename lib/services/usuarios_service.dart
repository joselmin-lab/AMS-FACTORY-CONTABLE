import 'package:flutter/foundation.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class Usuario {
  final String id;
  final String nombre;
  final String rol;
  final bool activo; // Usamos tu columna 'activo'

  Usuario({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      rol: json['rol']?.toString() ?? '',
      activo: json['activo'] == true, // Leemos tu columna booleana
    );
  }
}

class UsuariosService extends ChangeNotifier {
  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAdmins() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Consultamos tu tabla trayendo solo los que tienen rol ADMIN
      final response = await SupabaseService.client
          .from('perfiles')
          .select('id, nombre, rol, activo') // Tus columnas exactas
          .eq('rol', 'ADMIN') // Buscamos exactamente 'ADMIN' en mayúscula como en tu BD
          .order('nombre');

      _usuarios = (response as List)
          .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _error = "Error al cargar: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
enum RolUsuario { admin, contador, operario, viewer }

class Usuario {
  final String id;
  final String? nombre;
  final String? apellido;
  final String email;
  final RolUsuario rol;
  final String? avatarUrl;
  final bool activo;
  final DateTime? createdAt;

  const Usuario({
    required this.id,
    this.nombre,
    this.apellido,
    required this.email,
    this.rol = RolUsuario.viewer,
    this.avatarUrl,
    this.activo = true,
    this.createdAt,
  });

  String get nombreCompleto =>
      '${nombre ?? ''} ${apellido ?? ''}'.trim().isEmpty
          ? email
          : '${nombre ?? ''} ${apellido ?? ''}'.trim();

  String get rolLabel {
    switch (rol) {
      case RolUsuario.admin:
        return 'Administrador';
      case RolUsuario.contador:
        return 'Contador';
      case RolUsuario.operario:
        return 'Operario';
      case RolUsuario.viewer:
        return 'Visualizador';
    }
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    RolUsuario rolUsuario;
    switch (json['rol']?.toString()) {
      case 'admin':
        rolUsuario = RolUsuario.admin;
        break;
      case 'contador':
        rolUsuario = RolUsuario.contador;
        break;
      case 'operario':
        rolUsuario = RolUsuario.operario;
        break;
      default:
        rolUsuario = RolUsuario.viewer;
    }
    return Usuario(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString(),
      apellido: json['apellido']?.toString(),
      email: json['email']?.toString() ?? '',
      rol: rolUsuario,
      avatarUrl: json['avatar_url']?.toString(),
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'rol': rol.name,
        'avatar_url': avatarUrl,
        'activo': activo,
      };
}

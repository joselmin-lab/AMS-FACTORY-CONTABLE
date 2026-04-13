class Usuario {
  final String id;
  final String? email;
  final String? nombre;
  final String? phone;
  final DateTime? createdAt;

  Usuario({
    required this.id,
    this.email,
    this.nombre,
    this.phone,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'].toString(),
      email: json['email']?.toString(),
      nombre: json['nombre']?.toString(),
      phone: json['phone']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : null,
    );
  }
}
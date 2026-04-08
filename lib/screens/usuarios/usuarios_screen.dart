import 'package:flutter/material.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/usuario.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  // Sample data placeholder
  static final List<Usuario> _sampleUsers = [
    Usuario(
      id: '1',
      nombre: 'José',
      apellido: 'Administrador',
      email: 'admin@ams-factory.com',
      rol: RolUsuario.admin,
      activo: true,
    ),
    Usuario(
      id: '2',
      nombre: 'María',
      apellido: 'Contadora',
      email: 'contadora@ams-factory.com',
      rol: RolUsuario.contador,
      activo: true,
    ),
    Usuario(
      id: '3',
      nombre: 'Carlos',
      apellido: 'Operario',
      email: 'operario@ams-factory.com',
      rol: RolUsuario.operario,
      activo: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.usuarios),
        backgroundColor: AppColors.usuariosColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () {
              // TODO: open create user dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Función próximamente disponible')),
              );
            },
            tooltip: 'Agregar usuario',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsRow(),
          const SizedBox(height: 16),
          ..._sampleUsers.map((u) => _buildUserCard(context, u)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(
            '${_sampleUsers.length}', 'Total', AppColors.usuariosColor),
        const SizedBox(width: 12),
        _buildStatChip(
          '${_sampleUsers.where((u) => u.rol == RolUsuario.admin).length}',
          'Admins',
          AppColors.error,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          '${_sampleUsers.where((u) => u.activo).length}',
          'Activos',
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Usuario user) {
    final Color roleColor = _getRoleColor(user.rol);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withAlpha(51),
          child: Text(
            (user.nombre?.isNotEmpty == true
                    ? user.nombre![0]
                    : user.email[0])
                .toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
        ),
        title: Text(
          user.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email,
            style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.rolLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.activo
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: open user details
        },
      ),
    );
  }

  Color _getRoleColor(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.admin:
        return AppColors.error;
      case RolUsuario.contador:
        return AppColors.impositivoColor;
      case RolUsuario.operario:
        return AppColors.comprasColor;
      case RolUsuario.viewer:
        return AppColors.textSecondary;
    }
  }
}

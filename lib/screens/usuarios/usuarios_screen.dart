import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/services/usuarios_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuariosService>().fetchAdmins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.usuarios, style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.usuariosColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<UsuariosService>().fetchAdmins(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<UsuariosService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.usuariosColor));
          }

          if (service.error != null) {
            return Center(child: Text(service.error!, style: const TextStyle(color: AppColors.error)));
          }

          if (service.usuarios.isEmpty) {
            return const EmptyState(
              icon: Icons.admin_panel_settings_outlined,
              message: 'No hay administradores registrados.',
              actionLabel: '',
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.usuariosColor.withAlpha(26),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.usuariosColor, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personal Autorizado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.usuariosColor)),
                          Text(
                            'Estas personas tienen acceso total a la información contable y financiera.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.usuariosColor,
                  onRefresh: () => service.fetchAdmins(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: service.usuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = service.usuarios[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.usuariosColor.withAlpha(50),
                            foregroundColor: AppColors.usuariosColor,
                            child: Text(usuario.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(usuario.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          
                          // MOSTRAMOS SI ESTÁ ACTIVO EN VEZ DEL CORREO
                          subtitle: Row(
                            children: [
                              Icon(
                                usuario.activo ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 14, 
                                color: usuario.activo ? AppColors.success : AppColors.error
                              ),
                              const SizedBox(width: 4),
                              Text(usuario.activo ? 'Cuenta Activa' : 'Cuenta Inactiva', style: TextStyle(color: usuario.activo ? AppColors.success : AppColors.error)),
                            ],
                          ),

                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.usuariosColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(usuario.rol, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
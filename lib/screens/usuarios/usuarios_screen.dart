import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/services/usuarios_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';

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
      context.read<UsuariosService>().fetchUsuarios();
    });
  }

    void _mostrarFormulario() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    String rolSeleccionado = 'OPERADOR'; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B), // Fondo del diálogo
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Nuevo Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CAMPO NOMBRE
                  TextField(
                    controller: nombreCtrl, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A), // Fondo oscuro para el input
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), // Sin borde feo
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Espacio adentro
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAMPO EMAIL
                  TextField(
                    controller: emailCtrl, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email de acceso',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAMPO CONTRASEÑA
                  TextField(
                    controller: passCtrl, 
                    obscureText: true, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Contraseña (mínimo 6)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAMPO TELÉFONO
                  TextField(
                    controller: telefonoCtrl, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Teléfono (Opcional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // DROPDOWN PARA EL ROL
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E293B),
                    value: rolSeleccionado,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Rol del Sistema',
                      labelStyle: const TextStyle(color: Colors.tealAccent),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'OPERADOR', child: Text('OPERADOR (Acceso normal)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN (Acceso total)', style: TextStyle(color: Colors.amber))),
                    ],
                    onChanged: (val) {
                      setStateDialog(() { rolSeleccionado = val!; });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (emailCtrl.text.isEmpty || passCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa el email y la contraseña')));
                    return;
                  }
                  
                  final service = context.read<UsuariosService>();
                  final exito = await service.createUsuario(emailCtrl.text, passCtrl.text, nombreCtrl.text, telefonoCtrl.text, rolSeleccionado);
                  
                  if (exito && mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuario $rolSeleccionado creado'), backgroundColor: Colors.green));
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${service.error}'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Crear Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<UsuariosService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: service.usuarios.length,
              itemBuilder: (context, index) {
                final u = service.usuarios[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(u.nombre ?? u.email ?? 'Sin Nombre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Email: ${u.email ?? "S/N"}\nTel: ${u.phone ?? "-"}', style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // BOTÓN CAMBIAR CONTRASEÑA
                        IconButton(
                          icon: const Icon(Icons.vpn_key_rounded, color: Colors.amber),
                          onPressed: () async {
                            final passCtrl = TextEditingController();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: const Text('Cambiar Contraseña', style: TextStyle(color: Colors.white)),
                                content: TextField(
                                  controller: passCtrl,
                                  obscureText: true,
                                  decoration: const InputDecoration(labelText: 'Nueva Contraseña (mínimo 6)'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                    onPressed: () {
                                      if (passCtrl.text.length >= 6) Navigator.pop(ctx, true);
                                    },
                                    child: const Text('Guardar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && mounted) {
                              final exito = await context.read<UsuariosService>().resetPassword(u.id, passCtrl.text);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(exito ? 'Contraseña actualizada' : 'Error al actualizar: ${context.read<UsuariosService>().error}'),
                                backgroundColor: exito ? Colors.green : Colors.red,
                              ));
                            }
                          },
                        ),
                        // BOTÓN ELIMINAR USUARIO
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final conf = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: const Text('Eliminar Usuario', style: TextStyle(color: Colors.white)),
                                content: const Text('¿Borrar definitivamente el acceso de este usuario? No podrá volver a entrar a ninguna app.', style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            );
                            if (conf == true && mounted) {
                              final exito = await context.read<UsuariosService>().deleteUsuario(u.id);
                              if (!exito && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${context.read<UsuariosService>().error}'), backgroundColor: Colors.red));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _mostrarFormulario,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/models/cliente.dart';
import 'package:ams_control_contable/services/clientes_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesService>().fetchClientes();
    });
  }

  void _mostrarFormulario([Cliente? cliente]) {
    final isEditing = cliente != null;
    final nombreCtrl = TextEditingController(text: cliente?.nombre);
    final telefonoCtrl = TextEditingController(text: cliente?.telefono);
    final emailCtrl = TextEditingController(text: cliente?.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo'), style: const TextStyle(color: Colors.white)),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), style: const TextStyle(color: Colors.white)),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              final nuevo = Cliente(
                id: cliente?.id,
                nombre: nombreCtrl.text,
                telefono: telefonoCtrl.text,
                email: emailCtrl.text,
              );
              
              final service = context.read<ClientesService>();
              final exito = isEditing ? await service.updateCliente(nuevo) : await service.createCliente(nuevo);
              
              if (exito && mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado con éxito'), backgroundColor: Colors.green));
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${service.error}'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ClientesService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Directorio de Clientes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: service.clientes.length,
              itemBuilder: (context, index) {
                final c = service.clientes[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(c.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Tel: ${c.telefono ?? "S/N"} | Email: ${c.email ?? "S/N"}', style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _mostrarFormulario(c)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final conf = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                content: const Text('¿Eliminar este cliente?', style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (conf == true && mounted) {
                              final exito = await context.read<ClientesService>().deleteCliente(c.id!);
                              if (!exito && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<ClientesService>().error ?? 'Error'), backgroundColor: Colors.red));
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
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
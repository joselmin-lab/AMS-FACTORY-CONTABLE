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
        // Quitamos los colores oscuros forzados para que use el tema general
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quitamos los TextStyle(color: Colors.white)
              TextField(
                controller: nombreCtrl, 
                decoration: const InputDecoration(labelText: 'Nombre Completo')
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefonoCtrl, 
                decoration: const InputDecoration(labelText: 'Teléfono')
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl, 
                decoration: const InputDecoration(labelText: 'Email')
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.red))
          ),
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
      appBar: AppBar(
        title: const Text('Directorio de Clientes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal, // Color corporativo acorde al resto de tu app
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
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${c.telefono ?? 'Sin teléfono'} | ${c.email ?? 'Sin email'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _mostrarFormulario(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmar'),
                                content: const Text('¿Eliminar este cliente?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, eliminar', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirmar == true && mounted) {
                              await context.read<ClientesService>().deleteCliente(c.id!);
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/models/ingreso.dart';
import 'package:ams_control_contable/services/ingresos_service.dart';

class CrearIngresoScreen extends StatefulWidget {
  const CrearIngresoScreen({super.key});

  @override
  State<CrearIngresoScreen> createState() => _CrearIngresoScreenState();
}

class _CrearIngresoScreenState extends State<CrearIngresoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detalleCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  
  String _metodoPago = 'Transferencia';
  bool _facturado = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Ingreso Extra', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _detalleCtrl,
                decoration: const InputDecoration(labelText: 'Detalle o Motivo (Ej: Aporte capital)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto a ingresar', prefixText: 'Bs. '),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: const InputDecoration(labelText: 'Método de Ingreso'),
                items: ['Efectivo', 'QR', 'Transferencia', 'Tarjeta']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _metodoPago = val!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('¿Ingreso Facturado?'),
                subtitle: const Text('Activa si se emitió factura por este concepto'),
                value: _facturado,
                onChanged: (v) => setState(() => _facturado = v),
                activeColor: Colors.teal,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción adicional (Opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _isSaving ? null : _guardarIngreso,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Guardando...' : 'Registrar Ingreso en Caja'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarIngreso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final nuevoIngreso = Ingreso(
      detalle: _detalleCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      precio: double.parse(_precioCtrl.text),
      metodoPago: _metodoPago,
      facturado: _facturado,
      fecha: DateTime.now(),
    );

    final success = await context.read<IngresosService>().createIngreso(nuevoIngreso);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingreso extra registrado con éxito'), backgroundColor: Colors.teal));
      }
    }
  }
}
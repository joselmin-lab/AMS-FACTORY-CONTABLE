import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/models/salida.dart';
import 'package:ams_control_contable/services/salidas_service.dart';

class CrearSalidaScreen extends StatefulWidget {
  const CrearSalidaScreen({super.key});

  @override
  State<CrearSalidaScreen> createState() => _CrearSalidaScreenState();
}

class _CrearSalidaScreenState extends State<CrearSalidaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _detalleCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  
  bool _facturado = false;
  String _metodoPago = 'Efectivo';
  final List<String> _metodosPago = ['QR', 'Efectivo', 'Tarjeta', 'Crédito', 'Transferencia'];

  @override
  void dispose() {
    _detalleCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final nuevaSalida = Salida(
        detalle: _detalleCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        precio: double.parse(_precioCtrl.text),
        metodoPago: _metodoPago,
        facturado: _facturado,
        fecha: DateTime.now(),
      );

      context.read<SalidasService>().createSalida(nuevaSalida);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorModulo = Colors.deepOrange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Salida', style: TextStyle(color: Colors.white)),
        backgroundColor: colorModulo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _detalleCtrl,
                decoration: const InputDecoration(labelText: 'Detalle (Ej: Pago plomero, Mantenimiento)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción / Notas adicionales'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio / Monto', prefixText: 'Bs. '),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: const InputDecoration(labelText: 'Método de Pago'),
                items: _metodosPago.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _metodoPago = val!),
              ),
              const SizedBox(height: 16),

              // 3. REEMPLAZA EL CHECKBOX POR EL SWITCH
              SwitchListTile(
                title: const Text('¿Egreso Facturado?'),
                subtitle: const Text('Activa si se recibió factura por esta salida de dinero'),
                value: _facturado,
                onChanged: (v) => setState(() => _facturado = v),
                activeColor: Colors.deepOrange,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: colorModulo, foregroundColor: Colors.white),
                  child: const Text('Guardar Salida', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
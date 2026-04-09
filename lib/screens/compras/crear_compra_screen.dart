import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/models/compra.dart';
import 'package:ams_control_contable/services/compras_service.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class CrearCompraScreen extends StatefulWidget {
  const CrearCompraScreen({super.key});

  @override
  State<CrearCompraScreen> createState() => _CrearCompraScreenState();
}

class _CrearCompraScreenState extends State<CrearCompraScreen> {
  final _formKey = GlobalKey<FormState>();
  
  Map<String, dynamic>? _selectedItem; // El item de inventario seleccionado
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();
  
  bool _facturado = false;
  String _metodoPago = 'Transferencia / QR';
  
  final List<String> _metodosPago = [
    'Transferencia / QR',
    'Efectivo',
    'Tarjeta',
    'Crédito',
  ];

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _proveedorCtrl.dispose();
    super.dispose();
  }

  void _guardarCompra() {
    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar una parte o insumo válido del buscador')),
        );
        return;
      }

      final nuevaCompra = Compra(
        // Generamos un ID temporal. Luego Supabase le asignará un UUID real si es necesario
        id: null, 
        parteId: _selectedItem!['id'].toString(),
        parteNombre: _selectedItem!['nombre'] ?? 'Sin nombre',
        cantidad: double.parse(_cantidadCtrl.text),
        precio: double.parse(_precioCtrl.text),
        facturado: _facturado,
        proveedor: _proveedorCtrl.text,
        metodoPago: _metodoPago,
        fecha: DateTime.now(),
      );

      // AQUI ESTA LA CORRECCIÓN: Se usa createCompra en lugar de addCompra
      context.read<ComprasService>().createCompra(nuevaCompra);
      Navigator.pop(context);
    }
  }

  // Función que busca en Supabase las partes/insumos que se compran
  Future<List<Map<String, dynamic>>> _buscarEnInventario(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await SupabaseService.client
          .from('inventario')
          .select('id, codigo, nombre, categoria, origen, unidad')
          .or('origen.eq.COMPRA,categoria.eq.INSUMO,categoria.eq.MATERIA_PRIMA') 
          .ilike('nombre', '%$query%')
          .limit(10);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error buscando inventario: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Compra'),
        backgroundColor: AppColors.comprasColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Parte o Insumo (Buscar en Inventario)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // BUSCADOR CON AUTOCOMPLETAR
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (item) => '[${item['codigo']}] ${item['nombre']}',
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 2) return const Iterable<Map<String, dynamic>>.empty();
                  return await _buscarEnInventario(textEditingValue.text);
                },
                onSelected: (Map<String, dynamic> selection) {
                  setState(() {
                    _selectedItem = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Escribe el nombre del ítem...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  );
                },
              ),
              
              if (_selectedItem != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Categoría: ${_selectedItem!['categoria']}',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        // Muestra la unidad dinámicamente si ya hay un item seleccionado
                        suffixText: _selectedItem != null ? _selectedItem!['unidad'] : '',
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio Unitario',
                        prefixText: 'Bs. ',
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _proveedorCtrl,
                decoration: const InputDecoration(labelText: 'Proveedor'),
                validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: const InputDecoration(labelText: 'Método de Pago'),
                items: _metodosPago.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _metodoPago = val!),
              ),
              const SizedBox(height: 16),

              // 1. REEMPLAZA EL CHECKBOX POR EL SWITCH
              SwitchListTile(
                title: const Text('¿Compra Facturada?'),
                subtitle: const Text('Activa si el proveedor emitió factura con NIT'),
                value: _facturado,
                onChanged: (v) => setState(() => _facturado = v),
                activeColor: AppColors.comprasColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardarCompra,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.comprasColor),
                  child: const Text('Guardar Compra', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
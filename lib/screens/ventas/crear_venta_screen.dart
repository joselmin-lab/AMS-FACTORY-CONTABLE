import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/venta.dart';
import 'package:ams_control_contable/services/ventas_service.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({super.key});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  bool _facturado = false;
  String _metodoPago = AppStrings.pagoEfectivo;
  bool _isLoadingItems = true;

  List<Map<String, dynamic>> _inventoryItems = [];
  Map<String, dynamic>? _selectedItem;

  static const List<String> _metodosPago = [
    AppStrings.pagoQR,
    AppStrings.pagoEfectivo,
    AppStrings.pagoTarjeta,
    AppStrings.pagoCredito,
  ];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    try {
      final response = await SupabaseService.client
          .from('inventario')
          .select('id, codigo, nombre, stock_actual, categoria')
          // En ventas, generalmente se vende PRODUCTO_FINAL o PARTE 
          .order('nombre');
      
      if (mounted) {
        setState(() {
          _inventoryItems = List<Map<String, dynamic>>.from(response);
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _clienteCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _guardarVenta() {
    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar un producto del inventario', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
        return;
      }

      final cantidad = double.parse(_cantidadCtrl.text);
      final stockActual = (_selectedItem!['stock_actual'] as num?)?.toDouble() ?? 0;

      // Validación opcional: No dejar vender si no hay stock
      if (cantidad > stockActual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atención: Está vendiendo más stock del disponible ($stockActual).', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
        );
      }

      final nuevaVenta = Venta(
        id: null, // Que Supabase genere el ID
        parteId: _selectedItem!['id'].toString(),
        parteNombre: _selectedItem!['nombre'] ?? 'Sin nombre',
        cantidad: cantidad,
        precio: double.parse(_precioCtrl.text),
        facturado: _facturado,
        cliente: _clienteCtrl.text.trim(),
        metodoPago: _metodoPago,
        fecha: DateTime.now(),
      );

      context.read<VentasService>().createVenta(nuevaVenta);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.ventasColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingItems
          ? const Center(child: CircularProgressIndicator(color: AppColors.ventasColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Detalle del Producto a Vender', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (o) => '[${o['codigo']}] ${o['nombre']} (Stock: ${o['stock_actual']})',
                    optionsBuilder: (v) => v.text.isEmpty
                        ? _inventoryItems
                        : _inventoryItems.where((i) => '${i['codigo']} ${i['nombre']}'.toLowerCase().contains(v.text.toLowerCase())),
                    onSelected: (s) => setState(() => _selectedItem = s),
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: 'Producto (VENTA)',
                          hintText: 'Escriba para buscar...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        validator: (v) => _selectedItem == null ? 'Debe buscar y seleccionar un producto' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cantidadCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cantidad', prefixIcon: Icon(Icons.numbers)),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _precioCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Precio de Venta', prefixText: 'Bs. '),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Información de Venta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clienteCtrl,
                    decoration: const InputDecoration(labelText: 'Cliente', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _metodoPago,
                    decoration: const InputDecoration(labelText: 'Método de Pago', prefixIcon: Icon(Icons.payment)),
                    items: _metodosPago.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _metodoPago = v!),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('¿Venta con Factura?'),
                    value: _facturado,
                    onChanged: (v) => setState(() => _facturado = v ?? false),
                    activeColor: AppColors.ventasColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _guardarVenta,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ventasColor, foregroundColor: Colors.white),
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Venta', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
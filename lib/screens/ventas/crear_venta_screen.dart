import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/venta.dart';
import 'package:ams_control_contable/services/ventas_service.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

/// Represents a single product line in the sale form.
class _LineaVenta {
  Map<String, dynamic>? selectedItem;
  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  _LineaVenta()
      : cantidadCtrl = TextEditingController(),
        precioCtrl = TextEditingController();

  double get subtotal {
    final qty = double.tryParse(cantidadCtrl.text) ?? 0;
    final price = double.tryParse(precioCtrl.text) ?? 0;
    return qty * price;
  }

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({super.key});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _clienteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  bool _facturado = false;
  String _metodoPago = AppStrings.pagoEfectivo;
  DateTime _fechaVenta = DateTime.now();
  bool _isLoadingItems = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _inventoryItems = [];
  final List<_LineaVenta> _lineas = [];

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
    _lineas.add(_LineaVenta()); // Start with one line
  }

  Future<void> _loadInventoryItems() async {
    try {
      final response = await SupabaseService.client
          .from('inventario')
          .select('id, codigo, nombre, stock_actual, categoria')
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
    _clienteCtrl.dispose();
    _notasCtrl.dispose();
    for (final linea in _lineas) {
      linea.dispose();
    }
    super.dispose();
  }

  void _addLinea() {
    setState(() => _lineas.add(_LineaVenta()));
  }

  void _removeLinea(int index) {
    setState(() {
      _lineas[index].dispose();
      _lineas.removeAt(index);
    });
  }

  double get _totalGeneral =>
      _lineas.fold(0.0, (sum, l) => sum + l.subtotal);

  DateTime _combinarConHoraActual(DateTime soloFecha) {
    final ahora = DateTime.now();
    return DateTime(soloFecha.year, soloFecha.month, soloFecha.day, ahora.hour, ahora.minute, ahora.second);
  }

  Future<void> _guardarVenta() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate each line has a selected item
    for (int i = 0; i < _lineas.length; i++) {
      if (_lineas[i].selectedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Línea ${i + 1}: debe seleccionar un producto del inventario'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final ahora = _combinarConHoraActual(_fechaVenta);
    final notasTrimmed = _notasCtrl.text.trim();
    final ventas = _lineas.map((linea) {
      final cantidad = double.parse(linea.cantidadCtrl.text);
      final precio = double.parse(linea.precioCtrl.text);
      return Venta(
        id: null,
        parteId: linea.selectedItem!['id'].toString(),
        parteNombre: linea.selectedItem!['nombre'] ?? 'Sin nombre',
        cantidad: cantidad,
        precio: precio,
        facturado: _facturado,
        cliente: _clienteCtrl.text.trim(),
        metodoPago: _metodoPago,
        fecha: ahora,
        notas: notasTrimmed.isEmpty ? null : notasTrimmed,
      );
    }).toList();

    final ok = await context.read<VentasService>().createVentas(ventas);

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la venta'), backgroundColor: Colors.red),
        );
      }
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
                  // --- INFORMACIÓN GENERAL ---
                  const Text('Información de Venta',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                  SwitchListTile(
                    title: const Text('¿Venta Facturada?'),
                    subtitle: const Text('Activa si se emitió factura al cliente con NIT'),
                    value: _facturado,
                    onChanged: (v) => setState(() => _facturado = v),
                    activeColor: AppColors.ventasColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                   contentPadding: EdgeInsets.zero,
                   leading: const Icon(Icons.calendar_today, color: AppColors.ventasColor),
                   title: const Text('Fecha de Venta'),
                   subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaVenta)),
                   trailing: const Icon(Icons.edit_calendar),
                   onTap: () async {
                     final picked = await showDatePicker(
                       context: context,
                       initialDate: _fechaVenta,
                       firstDate: DateTime(2020),
                       lastDate: DateTime.now(),
                     );
                     if (picked != null) {
                       setState(() => _fechaVenta = picked);
                     }
                   },
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  // --- LÍNEAS DE PRODUCTOS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Productos a Vender',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('${_lineas.length} ítem(s)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Line items
                  for (int i = 0; i < _lineas.length; i++) _buildLineaWidget(i),

                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _addLinea,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Añadir producto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ventasColor,
                      side: const BorderSide(color: AppColors.ventasColor),
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  // --- TOTAL ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Venta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        'Bs. ${_totalGeneral.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ventasColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _guardarVenta,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ventasColor, foregroundColor: Colors.white),
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Guardando...' : 'Guardar Venta', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildLineaWidget(int index) {
    final linea = _lineas[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Producto ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                if (_lineas.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Eliminar línea',
                    onPressed: () => _removeLinea(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (o) => '[${o['codigo']}] ${o['nombre']} (Stock: ${o['stock_actual']})',
              optionsBuilder: (v) => v.text.isEmpty
                  ? _inventoryItems
                  : _inventoryItems.where((i) =>
                      '${i['codigo']} ${i['nombre']}'.toLowerCase().contains(v.text.toLowerCase())),
              onSelected: (s) => setState(() => linea.selectedItem = s),
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    hintText: 'Escriba para buscar...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  validator: (_) => linea.selectedItem == null ? 'Seleccione un producto' : null,
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: linea.cantidadCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cantidad', prefixIcon: Icon(Icons.numbers), isDense: true),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final qty = double.tryParse(v);
                      if (qty == null || qty <= 0) return 'Debe ser > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: linea.precioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio Unitario', prefixText: 'Bs. ', isDense: true),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) return 'Inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: Bs. ${linea.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ventasColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
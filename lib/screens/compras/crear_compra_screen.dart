import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/models/compra.dart';
import 'package:ams_control_contable/services/compras_service.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

/// Represents a single product line in the purchase form.
class _LineaCompra {
  Map<String, dynamic>? selectedItem;
  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  _LineaCompra()
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

class CrearCompraScreen extends StatefulWidget {
  const CrearCompraScreen({super.key});

  @override
  State<CrearCompraScreen> createState() => _CrearCompraScreenState();
}

class _CrearCompraScreenState extends State<CrearCompraScreen> {
  final _formKey = GlobalKey<FormState>();

  final _proveedorCtrl = TextEditingController();

  bool _facturado = false;
  String _metodoPago = 'Transferencia / QR';
  bool _isSaving = false;

  final List<String> _metodosPago = [
    'Transferencia / QR',
    'Efectivo',
    'Tarjeta',
    'Crédito',
  ];

  final List<_LineaCompra> _lineas = [];

  @override
  void initState() {
    super.initState();
    _lineas.add(_LineaCompra()); // Start with one line
  }

  @override
  void dispose() {
    _proveedorCtrl.dispose();
    for (final linea in _lineas) {
      linea.dispose();
    }
    super.dispose();
  }

  void _addLinea() {
    setState(() => _lineas.add(_LineaCompra()));
  }

  void _removeLinea(int index) {
    setState(() {
      _lineas[index].dispose();
      _lineas.removeAt(index);
    });
  }

  double get _totalGeneral =>
      _lineas.fold(0.0, (sum, l) => sum + l.subtotal);

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

  Future<void> _guardarCompra() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate each line has a selected item
    for (int i = 0; i < _lineas.length; i++) {
      if (_lineas[i].selectedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Línea ${i + 1}: debe seleccionar un ítem válido del buscador'),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final ahora = DateTime.now();
    final compras = _lineas.map((linea) {
      final cantidad = double.parse(linea.cantidadCtrl.text);
      final precio = double.parse(linea.precioCtrl.text);
      return Compra(
        id: null,
        parteId: linea.selectedItem!['id'].toString(),
        parteNombre: linea.selectedItem!['nombre'] ?? 'Sin nombre',
        cantidad: cantidad,
        precio: precio,
        facturado: _facturado,
        proveedor: _proveedorCtrl.text.trim(),
        metodoPago: _metodoPago,
        fecha: ahora,
      );
    }).toList();

    final ok = await context.read<ComprasService>().createCompras(compras);

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la compra'), backgroundColor: Colors.red),
        );
      }
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
              // --- INFORMACIÓN GENERAL ---
              const Text('Información de Compra',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _proveedorCtrl,
                decoration: const InputDecoration(labelText: 'Proveedor', prefixIcon: Icon(Icons.business)),
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

              SwitchListTile(
                title: const Text('¿Compra Facturada?'),
                subtitle: const Text('Activa si el proveedor emitió factura con NIT'),
                value: _facturado,
                onChanged: (v) => setState(() => _facturado = v),
                activeColor: AppColors.comprasColor,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // --- LÍNEAS DE PRODUCTOS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ítems a Comprar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${_lineas.length} ítem(s)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),

              for (int i = 0; i < _lineas.length; i++) _buildLineaWidget(i),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addLinea,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Añadir ítem'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.comprasColor,
                  side: const BorderSide(color: AppColors.comprasColor),
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
                  const Text('Total Compra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Bs. ${_totalGeneral.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.comprasColor),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _guardarCompra,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.comprasColor),
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar Compra', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
                Text('Ítem ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                if (_lineas.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Eliminar ítem',
                    onPressed: () => _removeLinea(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (item) => '[${item['codigo']}] ${item['nombre']}',
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.length < 2) return const Iterable<Map<String, dynamic>>.empty();
                return await _buscarEnInventario(textEditingValue.text);
              },
              onSelected: (Map<String, dynamic> selection) {
                setState(() => linea.selectedItem = selection);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Escribe el nombre del ítem...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  validator: (_) => linea.selectedItem == null ? 'Seleccione un ítem' : null,
                );
              },
            ),
            if (linea.selectedItem != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Categoría: ${linea.selectedItem!['categoria']}  |  Unidad: ${linea.selectedItem!['unidad'] ?? ''}',
                  style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: linea.cantidadCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      suffixText: linea.selectedItem?['unidad'] as String? ?? '',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) return 'Debe ser > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: linea.precioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio Unitario',
                      prefixText: 'Bs. ',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (double.tryParse(value) == null) return 'Inválido';
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
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.comprasColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
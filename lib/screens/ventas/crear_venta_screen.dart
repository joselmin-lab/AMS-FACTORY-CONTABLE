import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/venta.dart';
import 'package:ams_control_contable/services/ventas_service.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';

class CrearVentaScreen extends StatefulWidget {
  final String? ventaId;

  const CrearVentaScreen({super.key, this.ventaId});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _parteController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _clienteController = TextEditingController();
  final _notasController = TextEditingController();

  bool _facturado = false;
  String _metodoPago = AppStrings.pagoEfectivo;

  bool get _isEditing => widget.ventaId != null;

  static const List<String> _metodosPago = [
    AppStrings.pagoQR,
    AppStrings.pagoEfectivo,
    AppStrings.pagoTarjeta,
    AppStrings.pagoCredito,
  ];

  @override
  void dispose() {
    _parteController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _clienteController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final venta = Venta(
      id: widget.ventaId,
      parteNombre: _parteController.text.trim(),
      cantidad: double.parse(_cantidadController.text.trim()),
      precio: double.parse(_precioController.text.trim()),
      facturado: _facturado,
      cliente: _clienteController.text.trim(),
      metodoPago: _metodoPago,
      fecha: DateTime.now(),
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
    );

    final service = context.read<VentasService>();
    bool success;

    if (_isEditing) {
      success = await service.updateVenta(venta);
    } else {
      success = await service.createVenta(venta);
    }

    if (mounted) {
      if (success) {
        showSuccessSnackbar(context, AppStrings.registroGuardado);
        Navigator.pop(context);
      } else {
        showErrorSnackbar(context, service.error ?? 'Error al guardar');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Venta' : 'Nueva Venta'),
        backgroundColor: AppColors.ventasColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Detalle del Producto'),
            const SizedBox(height: 12),
            _buildSearchField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCantidadField()),
                const SizedBox(width: 12),
                Expanded(child: _buildPrecioField()),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Información de Venta'),
            const SizedBox(height: 12),
            _buildClienteField(),
            const SizedBox(height: 16),
            _buildMetodoPagoField(),
            const SizedBox(height: 16),
            _buildFacturadoField(),
            const SizedBox(height: 16),
            _buildNotasField(),
            const SizedBox(height: 24),
            _buildTotalPreview(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _parteController,
      decoration: InputDecoration(
        labelText: 'Parte / Insumo / Producto Final',
        hintText: 'Buscar parte, insumo o producto...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _parteController.clear(),
        ),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? AppStrings.campoRequerido : null,
    );
  }

  Widget _buildCantidadField() {
    return TextFormField(
      controller: _cantidadController,
      decoration: const InputDecoration(
        labelText: AppStrings.cantidad,
        prefixIcon: Icon(Icons.numbers_rounded),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return AppStrings.campoRequerido;
        if (double.tryParse(v) == null) return AppStrings.valorInvalido;
        return null;
      },
    );
  }

  Widget _buildPrecioField() {
    return TextFormField(
      controller: _precioController,
      decoration: const InputDecoration(
        labelText: AppStrings.precio,
        prefixIcon: Icon(Icons.attach_money_rounded),
        prefixText: 'Bs. ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return AppStrings.campoRequerido;
        if (double.tryParse(v) == null) return AppStrings.valorInvalido;
        return null;
      },
    );
  }

  Widget _buildClienteField() {
    return TextFormField(
      controller: _clienteController,
      decoration: const InputDecoration(
        labelText: AppStrings.cliente,
        prefixIcon: Icon(Icons.person_rounded),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? AppStrings.campoRequerido : null,
    );
  }

  Widget _buildMetodoPagoField() {
    return DropdownButtonFormField<String>(
      value: _metodoPago,
      decoration: const InputDecoration(
        labelText: AppStrings.metodoPago,
        prefixIcon: Icon(Icons.payment_rounded),
      ),
      items: _metodosPago
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) => setState(() => _metodoPago = v!),
    );
  }

  Widget _buildFacturadoField() {
    return Card(
      margin: EdgeInsets.zero,
      child: CheckboxListTile(
        title: const Text(
          AppStrings.facturado,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Marcar si la venta tiene factura'),
        value: _facturado,
        onChanged: (v) => setState(() => _facturado = v ?? false),
        activeColor: AppColors.ventasColor,
        secondary: Icon(
          _facturado
              ? Icons.receipt_long_rounded
              : Icons.receipt_outlined,
          color: AppColors.ventasColor,
        ),
      ),
    );
  }

  Widget _buildNotasField() {
    return TextFormField(
      controller: _notasController,
      decoration: const InputDecoration(
        labelText: AppStrings.notas,
        prefixIcon: Icon(Icons.note_rounded),
        hintText: 'Observaciones adicionales (opcional)',
      ),
      maxLines: 2,
    );
  }

  Widget _buildTotalPreview() {
    return ListenableBuilder(
      listenable: Listenable.merge([_cantidadController, _precioController]),
      builder: (context, _) {
        final qty = double.tryParse(_cantidadController.text) ?? 0;
        final price = double.tryParse(_precioController.text) ?? 0;
        final t = qty * price;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.ventasColor.withAlpha(13),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.ventasColor.withAlpha(77)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.total,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                'Bs. ${t.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.ventasColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<VentasService>(
      builder: (context, service, _) {
        return ElevatedButton.icon(
          onPressed: service.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ventasColor,
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: service.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_isEditing ? 'Actualizar Venta' : 'Guardar Venta'),
        );
      },
    );
  }
}

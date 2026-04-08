import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/services/importaciones_service.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';

class CrearImportacionScreen extends StatefulWidget {
  final String? importacionId;

  const CrearImportacionScreen({super.key, this.importacionId});

  @override
  State<CrearImportacionScreen> createState() =>
      _CrearImportacionScreenState();
}

class _CrearImportacionScreenState extends State<CrearImportacionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Items list
  final List<_ItemFormRow> _itemRows = [];

  // Other fields
  final _porcentajeGAController =
      TextEditingController(text: '');
  final _porcentajeIVAController =
      TextEditingController(text: '13');
  final _tipoCambioController =
      TextEditingController(text: '6.96');
  final _costoFleteController = TextEditingController(text: '0');
  final _costoDespachanteController =
      TextEditingController(text: '0');
  final _otrosCostosController =
      TextEditingController(text: '0');
  final _notasController = TextEditingController();

  bool get _isEditing => widget.importacionId != null;

  @override
  void initState() {
    super.initState();
    _addItemRow();
    _addListeners();
  }

  void _addListeners() {
    for (final c in [
      _porcentajeGAController,
      _porcentajeIVAController,
      _tipoCambioController,
      _costoFleteController,
      _costoDespachanteController,
      _otrosCostosController,
    ]) {
      c.addListener(_recalculate);
    }
  }

  void _addItemRow() {
    setState(() {
      _itemRows.add(_ItemFormRow(onChanged: _recalculate));
    });
  }

  void _removeItemRow(int index) {
    if (_itemRows.length > 1) {
      setState(() {
        _itemRows[index].dispose();
        _itemRows.removeAt(index);
      });
    }
  }

  void _recalculate() => setState(() {});

  double get _subtotalUsFabrica => _itemRows.fold(0.0, (sum, row) {
        final qty = double.tryParse(row.cantidadController.text) ?? 0;
        final price = double.tryParse(row.precioController.text) ?? 0;
        return sum + qty * price;
      });

  double get _porcentajeGA =>
      double.tryParse(_porcentajeGAController.text) ?? 0;
  double get _porcentajeIVA =>
      double.tryParse(_porcentajeIVAController.text) ?? 0;
  double get _tipoCambio =>
      double.tryParse(_tipoCambioController.text) ?? 0;
  double get _costoFlete =>
      double.tryParse(_costoFleteController.text) ?? 0;
  double get _costoDespachante =>
      double.tryParse(_costoDespachanteController.text) ?? 0;
  double get _otrosCostos =>
      double.tryParse(_otrosCostosController.text) ?? 0;

  double get _costoGA => _subtotalUsFabrica * (_porcentajeGA / 100);
  double get _costoIVA =>
      (_subtotalUsFabrica + _costoGA) * (_porcentajeIVA / 100);
  double get _subtotalBs =>
      (_subtotalUsFabrica + _costoGA + _costoIVA) * _tipoCambio;
  double get _costoTotal =>
      _subtotalBs + _costoFlete + _costoDespachante + _otrosCostos;

  @override
  void dispose() {
    for (final row in _itemRows) {
      row.dispose();
    }
    _porcentajeGAController.dispose();
    _porcentajeIVAController.dispose();
    _tipoCambioController.dispose();
    _costoFleteController.dispose();
    _costoDespachanteController.dispose();
    _otrosCostosController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final items = _itemRows
        .map((row) => ItemImportacion(
              parteNombre: row.parteController.text.trim(),
              cantidad:
                  double.tryParse(row.cantidadController.text) ?? 0,
              precioUsFabrica:
                  double.tryParse(row.precioController.text) ?? 0,
            ))
        .toList();

    final importacion = Importacion(
      id: widget.importacionId,
      items: items,
      porcentajeGA: _porcentajeGA,
      porcentajeIVA: _porcentajeIVA,
      tipoCambio: _tipoCambio,
      costoFlete: _costoFlete,
      costoDespachante: _costoDespachante,
      otrosCostos: _otrosCostos,
      fecha: DateTime.now(),
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
    );

    final service = context.read<ImportacionesService>();
    bool success;
    if (_isEditing) {
      success = await service.updateImportacion(importacion);
    } else {
      success = await service.createImportacion(importacion);
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
        title: Text(
            _isEditing ? 'Editar Importación' : 'Nueva Importación'),
        backgroundColor: AppColors.importacionesColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Partes / Insumos'),
            const SizedBox(height: 8),
            ..._itemRows.asMap().entries.map((e) => _buildItemRow(
                  e.key,
                  e.value,
                )),
            TextButton.icon(
              onPressed: _addItemRow,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar ítem'),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Datos de Importación'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNumericField(
                    controller: _porcentajeGAController,
                    label: AppStrings.porcentajeGA,
                    suffix: '%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumericField(
                    controller: _porcentajeIVAController,
                    label: AppStrings.porcentajeIVA,
                    suffix: '%',
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNumericField(
              controller: _tipoCambioController,
              label: AppStrings.tipoCambio,
              prefix: 'US\$ 1 = Bs.',
              required: true,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Costos Adicionales'),
            const SizedBox(height: 12),
            _buildNumericField(
              controller: _costoFleteController,
              label: AppStrings.costoFlete,
              prefix: 'Bs.',
            ),
            const SizedBox(height: 16),
            _buildNumericField(
              controller: _costoDespachanteController,
              label: AppStrings.costoDespachante,
              prefix: 'Bs.',
            ),
            const SizedBox(height: 16),
            _buildNumericField(
              controller: _otrosCostosController,
              label: AppStrings.otrosCostos,
              prefix: 'Bs.',
            ),
            const SizedBox(height: 16),
            _buildNotasField(),
            const SizedBox(height: 24),
            _buildCostoTotalPreview(),
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

  Widget _buildItemRow(int index, _ItemFormRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Ítem ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.importacionesColor)),
                const Spacer(),
                if (_itemRows.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.error),
                    onPressed: () => _removeItemRow(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: row.parteController,
              decoration: const InputDecoration(
                labelText: 'Parte / Insumo',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? AppStrings.campoRequerido : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,4}')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.campoRequerido;
                      }
                      if (double.tryParse(v) == null) {
                        return AppStrings.valorInvalido;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio US\$',
                      prefixText: 'US\$ ',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,4}')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.campoRequerido;
                      }
                      if (double.tryParse(v) == null) {
                        return AppStrings.valorInvalido;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix != null ? '$prefix ' : null,
        suffixText: suffix,
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
      ],
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return AppStrings.campoRequerido;
              if (double.tryParse(v) == null) return AppStrings.valorInvalido;
              return null;
            }
          : null,
    );
  }

  Widget _buildNotasField() {
    return TextFormField(
      controller: _notasController,
      decoration: const InputDecoration(
        labelText: AppStrings.notas,
        prefixIcon: Icon(Icons.note_rounded),
      ),
      maxLines: 2,
    );
  }

  Widget _buildCostoTotalPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.importacionesColor.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.importacionesColor.withAlpha(77)),
      ),
      child: Column(
        children: [
          _buildCostRow('Subtotal US\$ Fábrica',
              'US\$ ${_subtotalUsFabrica.toStringAsFixed(2)}'),
          _buildCostRow(
              'GA (${_porcentajeGA.toStringAsFixed(1)}%)',
              'US\$ ${_costoGA.toStringAsFixed(2)}'),
          _buildCostRow(
              'IVA (${_porcentajeIVA.toStringAsFixed(1)}%)',
              'US\$ ${_costoIVA.toStringAsFixed(2)}'),
          _buildCostRow(
              'Subtotal en Bs. (TC: ${_tipoCambio.toStringAsFixed(2)})',
              'Bs. ${_subtotalBs.toStringAsFixed(2)}'),
          _buildCostRow('Flete',
              'Bs. ${_costoFlete.toStringAsFixed(2)}'),
          _buildCostRow('Despachante',
              'Bs. ${_costoDespachante.toStringAsFixed(2)}'),
          _buildCostRow('Otros',
              'Bs. ${_otrosCostos.toStringAsFixed(2)}'),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.costoTotal,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'Bs. ${_costoTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.importacionesColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<ImportacionesService>(
      builder: (context, service, _) {
        return ElevatedButton.icon(
          onPressed: service.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.importacionesColor,
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
          label: Text(_isEditing
              ? 'Actualizar Importación'
              : 'Guardar Importación'),
        );
      },
    );
  }
}

class _ItemFormRow {
  final TextEditingController parteController = TextEditingController();
  final TextEditingController cantidadController =
      TextEditingController();
  final TextEditingController precioController =
      TextEditingController();
  final VoidCallback onChanged;

  _ItemFormRow({required this.onChanged}) {
    parteController.addListener(onChanged);
    cantidadController.addListener(onChanged);
    precioController.addListener(onChanged);
  }

  void dispose() {
    parteController.dispose();
    cantidadController.dispose();
    precioController.dispose();
  }
}

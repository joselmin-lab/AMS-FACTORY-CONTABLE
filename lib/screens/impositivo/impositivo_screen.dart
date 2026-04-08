import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/tax_config.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';

class ImpositivoScreen extends StatefulWidget {
  const ImpositivoScreen({super.key});

  @override
  State<ImpositivoScreen> createState() => _ImpositivoScreenState();
}

class _ImpositivoScreenState extends State<ImpositivoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _ivaVentasController;
  late final TextEditingController _itVentasController;
  late final TextEditingController _ivaComprasController;
  late final TextEditingController _iueController;

  TaxConfig _config = TaxConfig.defaults();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ivaVentasController =
        TextEditingController(text: _config.ivaVentas.toString());
    _itVentasController =
        TextEditingController(text: _config.itVentas.toString());
    _ivaComprasController =
        TextEditingController(text: _config.ivaCompras.toString());
    _iueController =
        TextEditingController(text: _config.iueUtilidades.toString());
  }

  @override
  void dispose() {
    _ivaVentasController.dispose();
    _itVentasController.dispose();
    _ivaComprasController.dispose();
    _iueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // TODO: persist to Supabase via a TaxConfigService
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _config = _config.copyWith(
        ivaVentas: double.parse(_ivaVentasController.text),
        itVentas: double.parse(_itVentasController.text),
        ivaCompras: double.parse(_ivaComprasController.text),
        iueUtilidades: double.parse(_iueController.text),
      );
      _isSaving = false;
    });

    if (mounted) {
      showSuccessSnackbar(context, 'Configuración impositiva guardada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.impositivo),
        backgroundColor: AppColors.impositivoColor,
      ),
      drawer: const AppDrawer(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 20),
            _buildSectionHeader('Configuración de Ventas'),
            const SizedBox(height: 12),
            _buildTaxField(
              controller: _ivaVentasController,
              label: AppStrings.ivaVentas,
              description:
                  'Porcentaje de IVA que se aplica a las ventas facturadas.',
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(height: 16),
            _buildTaxField(
              controller: _itVentasController,
              label: AppStrings.itVentas,
              description:
                  'Impuesto a las Transacciones sobre las ventas.',
              icon: Icons.swap_horiz_rounded,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Configuración de Compras'),
            const SizedBox(height: 12),
            _buildTaxField(
              controller: _ivaComprasController,
              label: AppStrings.ivaCompras,
              description:
                  'Porcentaje de IVA que se puede acreditar en compras.',
              icon: Icons.shopping_cart_rounded,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Configuración de Utilidades'),
            const SizedBox(height: 12),
            _buildTaxField(
              controller: _iueController,
              label: AppStrings.iueUtilidades,
              description:
                  'Impuesto sobre las Utilidades de las Empresas (IUE).',
              icon: Icons.business_center_rounded,
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.impositivoColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.impositivoColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.impositivoColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Configura los porcentajes impositivos que se usarán en el cálculo automático de impuestos en cada módulo.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.impositivoColor,
              ),
            ),
          ),
        ],
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

  Widget _buildTaxField({
    required TextEditingController controller,
    required String label,
    required String description,
    required IconData icon,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.impositivoColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                suffixText: '%',
                isDense: true,
                prefixIcon: Icon(icon,
                    color: AppColors.impositivoColor, size: 18),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return AppStrings.campoRequerido;
                }
                final n = double.tryParse(v);
                if (n == null || n < 0 || n > 100) {
                  return 'Ingrese un porcentaje válido (0–100)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.impositivoColor,
        minimumSize: const Size(double.infinity, 48),
      ),
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_rounded),
      label: const Text('Guardar Configuración'),
    );
  }
}

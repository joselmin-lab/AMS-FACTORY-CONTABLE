import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/tax_config.dart';
import 'package:ams_control_contable/services/impositivo_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';

class ImpositivoScreen extends StatefulWidget {
  const ImpositivoScreen({super.key});

  @override
  State<ImpositivoScreen> createState() => _ImpositivoScreenState();
}

class _ImpositivoScreenState extends State<ImpositivoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _ivaVentasController;
  late TextEditingController _itVentasController;
  late TextEditingController _ivaComprasController;
  late TextEditingController _iueController;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ivaVentasController = TextEditingController();
    _itVentasController = TextEditingController();
    _ivaComprasController = TextEditingController();
    _iueController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImpositivoService>().fetchConfig().then((_) => _llenarCampos());
    });
  }

  void _llenarCampos() {
    final config = context.read<ImpositivoService>().config;
    _ivaVentasController.text = config.ivaVentas.toString();
    _itVentasController.text = config.itVentas.toString();
    _ivaComprasController.text = config.ivaCompras.toString();
    _iueController.text = config.iueUtilidades.toString();
    if (mounted) setState(() => _initialized = true);
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

    final nuevaConfig = TaxConfig(
      ivaVentas: double.parse(_ivaVentasController.text),
      itVentas: double.parse(_itVentasController.text),
      ivaCompras: double.parse(_ivaComprasController.text),
      iueUtilidades: double.parse(_iueController.text),
    );

    final exito = await context.read<ImpositivoService>().updateConfig(nuevaConfig);
    if (mounted) {
      setState(() => _isSaving = false);
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración impositiva guardada con éxito'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${context.read<ImpositivoService>().error}'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ImpositivoService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.impositivo, style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.impositivoColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: service.isLoading || !_initialized
          ? const Center(child: CircularProgressIndicator(color: AppColors.impositivoColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Configuración de Ventas'),
                  const SizedBox(height: 12),
                  _buildTaxField(controller: _ivaVentasController, label: AppStrings.ivaVentas, description: 'Porcentaje de IVA que se aplica a las ventas facturadas.', icon: Icons.receipt_long_rounded),
                  const SizedBox(height: 16),
                  _buildTaxField(controller: _itVentasController, label: AppStrings.itVentas, description: 'Impuesto a las Transacciones sobre las ventas.', icon: Icons.swap_horiz_rounded),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Configuración de Compras y Rentabilidad'),
                  const SizedBox(height: 12),
                  _buildTaxField(controller: _ivaComprasController, label: AppStrings.ivaCompras, description: 'Crédito fiscal generado por compras facturadas.', icon: Icons.shopping_cart_rounded),
                  const SizedBox(height: 16),
                  _buildTaxField(controller: _iueController, label: AppStrings.iueUtilidades, description: 'Impuesto a las Utilidades de las Empresas sobre la utilidad neta.', icon: Icons.account_balance_rounded),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Guardando...' : 'Guardar Configuración', style: const TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.impositivoColor, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.impositivoColor.withAlpha(26), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.impositivoColor.withAlpha(76))),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.impositivoColor),
          SizedBox(width: 12),
          Expanded(
            child: Text('Estos valores se utilizarán para calcular tus proyecciones tributarias mensuales y la utilidad real en el Dashboard.', style: TextStyle(color: AppColors.impositivoColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }

  Widget _buildTaxField({required TextEditingController controller, required String label, required String description, required IconData icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(labelText: label, helperText: description, helperMaxLines: 2, prefixIcon: Icon(icon, color: AppColors.impositivoColor), suffixText: '%'),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final val = double.tryParse(v);
        if (val == null || val < 0 || val > 100) return 'Valor entre 0 y 100';
        return null;
      },
    );
  }
}
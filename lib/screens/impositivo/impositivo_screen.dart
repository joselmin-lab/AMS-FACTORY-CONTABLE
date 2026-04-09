import 'package:flutter/material.dart';
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
  late TextEditingController _saldoIvaController;
  late TextEditingController _saldoIueController;
  
  int _mesCierre = 12;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ivaVentasController = TextEditingController();
    _itVentasController = TextEditingController();
    _ivaComprasController = TextEditingController();
    _iueController = TextEditingController();
    _saldoIvaController = TextEditingController();
    _saldoIueController = TextEditingController();
    
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
    _saldoIvaController.text = config.saldoIvaAnterior.toString();
    _saldoIueController.text = config.saldoIuePorCompensar.toString();
    _mesCierre = config.mesCierreGestion;

    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final nuevaConfig = TaxConfig(
      ivaVentas: double.parse(_ivaVentasController.text.replaceAll(',', '.')),
      itVentas: double.parse(_itVentasController.text.replaceAll(',', '.')),
      ivaCompras: double.parse(_ivaComprasController.text.replaceAll(',', '.')),
      iueUtilidades: double.parse(_iueController.text.replaceAll(',', '.')),
      saldoIvaAnterior: double.parse(_saldoIvaController.text.replaceAll(',', '.')),
      saldoIuePorCompensar: double.parse(_saldoIueController.text.replaceAll(',', '.')),
      mesCierreGestion: _mesCierre,
    );

    final exito = await context.read<ImpositivoService>().updateConfig(nuevaConfig);
    if (mounted) {
      setState(() => _isSaving = false);
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada con éxito'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${context.read<ImpositivoService>().error}'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ImpositivoService>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.impositivo, style: TextStyle(color: Colors.white)), backgroundColor: AppColors.impositivoColor, iconTheme: const IconThemeData(color: Colors.white)),
      drawer: const AppDrawer(),
      body: service.isLoading || !_initialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Porcentajes de Ley', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.impositivoColor)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _ivaVentasController, decoration: const InputDecoration(labelText: 'IVA Ventas %'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(controller: _itVentasController, decoration: const InputDecoration(labelText: 'IT Ventas %'), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _ivaComprasController, decoration: const InputDecoration(labelText: 'IVA Compras %'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(controller: _iueController, decoration: const InputDecoration(labelText: 'IUE Utilidades %'), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('Saldos a Favor (Memoria Fiscal)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.impositivoColor)),
                    const Text('Estos montos se actualizan solos al "Cerrar Mes" en el Dashboard, pero puedes ajustarlos manualmente aquí si es necesario.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _saldoIvaController, decoration: const InputDecoration(labelText: 'Saldo IVA a Favor (Bs)'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(controller: _saldoIueController, decoration: const InputDecoration(labelText: 'IUE Pagado por Compensar (Bs)'), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('Cierre de Gestión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.impositivoColor)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Mes de Cierre de Gestión Fiscal'),
                      value: _mesCierre,
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('Marzo (Industrial, Petrolero)')),
                        DropdownMenuItem(value: 6, child: Text('Junio (Gomero, Agrícola)')),
                        DropdownMenuItem(value: 9, child: Text('Septiembre (Minero)')),
                        DropdownMenuItem(value: 12, child: Text('Diciembre (Comercial, Servicios)')),
                      ],
                      onChanged: (val) => setState(() => _mesCierre = val!),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: AppColors.impositivoColor, foregroundColor: Colors.white),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Configuración'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
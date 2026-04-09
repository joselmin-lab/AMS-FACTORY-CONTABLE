import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/services/importaciones_service.dart';

class CrearImportacionScreen extends StatefulWidget {
  final String? carpetaId;

  const CrearImportacionScreen({super.key, this.carpetaId});

  @override
  State<CrearImportacionScreen> createState() => _CrearImportacionScreenState();
}

class _CrearImportacionScreenState extends State<CrearImportacionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Datos Base
  final _despachoCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();
  final _tipoCambioCtrl = TextEditingController(text: '6.96');
  final _notasCtrl = TextEditingController();

  // Estimaciones
  final _fleteEstCtrl = TextEditingController(text: '0');
  final _aduanaEstCtrl = TextEditingController(text: '0');
  final _otrosEstCtrl = TextEditingController(text: '0');

  bool _isSaving = false;

  @override
  void dispose() {
    _despachoCtrl.dispose();
    _proveedorCtrl.dispose();
    _tipoCambioCtrl.dispose();
    _notasCtrl.dispose();
    _fleteEstCtrl.dispose();
    _aduanaEstCtrl.dispose();
    _otrosEstCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearCarpeta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final nuevaCarpeta = ImpCarpeta(
      numeroDespacho: _despachoCtrl.text.trim().toUpperCase(),
      proveedor: _proveedorCtrl.text.trim(),
      fechaApertura: DateTime.now(),
      tipoCambio: double.parse(_tipoCambioCtrl.text),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      
      // Capturamos las estimaciones
      fleteEstimado: double.parse(_fleteEstCtrl.text),
      aduanaEstimada: double.parse(_aduanaEstCtrl.text),
      otrosGastosEstimados: double.parse(_otrosEstCtrl.text),
    );

    final success = await context.read<ImportacionesService>().crearCarpeta(nuevaCarpeta);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carpeta abierta con éxito'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir la carpeta: ${context.read<ImportacionesService>().error}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apertura de Carpeta', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.importacionesColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Abre el contenedor virtual para tu pedido. Configura los datos base y proyecta los gastos futuros.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              
              // SECCIÓN: DATOS BASE
              const Text('1. Información Base', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.importacionesColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _despachoCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Nº de Despacho', prefixIcon: Icon(Icons.tag_rounded)),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _tipoCambioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'TC Oficial (Bs/USD)', prefixIcon: Icon(Icons.currency_exchange_rounded)),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proveedorCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Proveedor / Fábrica Origen', prefixIcon: Icon(Icons.business_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              
              const SizedBox(height: 32),
              
              // SECCIÓN: ESTIMACIONES DE GASTO
              const Text('2. Estimación de Gastos Operativos (Proyección)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.importacionesColor)),
              const Text('Estos valores no afectan contabilidad aún, sirven para proyectar tu Costo Landed inicial.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fleteEstCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Flete Estimado', prefixText: 'Bs. ', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _aduanaEstCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Aduana Estimada', prefixText: 'Bs. ', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _otrosEstCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Otros / Seguro', prefixText: 'Bs. ', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notas / Puerto de Origen', alignLabelWithHint: true),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.importacionesColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _crearCarpeta,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.create_new_folder_rounded),
                label: Text(_isSaving ? 'Abriendo...' : 'Abrir Carpeta de Importación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
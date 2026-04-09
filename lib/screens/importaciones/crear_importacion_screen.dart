import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final _dateFormat = DateFormat('dd/MM/yyyy');
  
  final _despachoCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();
  final _tipoCambioCtrl = TextEditingController(text: '6.96');
  final _notasCtrl = TextEditingController();
  String _incoterm = 'FOB';
  DateTime? _fechaEmbarque;
  DateTime? _fechaLlegada;

  bool _usaImpuestosGlobales = true;
  final _gaGlobalCtrl = TextEditingController(text: '10');
  final _ivaGlobalCtrl = TextEditingController(text: '14.94');
  final _pctDeclaracionCtrl = TextEditingController(text: '100'); 

  final _fleteUsdCtrl = TextEditingController(text: '0');
  final _despachanteBsCtrl = TextEditingController(text: '0');
  final _docBsCtrl = TextEditingController(text: '0');
  final _almBsCtrl = TextEditingController(text: '0');

  bool _isSaving = false;

  String _obtenerMensajeIncoterm() {
    if (_incoterm == 'CIF') return 'CIF: Flete marítimo y seguro incluidos en el pago al proveedor.';
    if (_incoterm == 'EXW') return 'EXW: Considera el flete interno desde la fábrica al puerto.';
    return 'FOB: Debes pagar el flete marítimo por separado a la Naviera.';
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esEmbarque) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.importacionesColor)), child: child!),
    );
    if (picked != null) {
      setState(() {
        if (esEmbarque) _fechaEmbarque = picked;
        else _fechaLlegada = picked;
      });
    }
  }

  Future<void> _crearCarpeta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final nuevaCarpeta = ImpCarpeta(
      numeroDespacho: _despachoCtrl.text.trim().toUpperCase(),
      proveedor: _proveedorCtrl.text.trim(),
      incoterm: _incoterm,
      fechaApertura: DateTime.now(),
      fechaEmbarque: _fechaEmbarque,
      fechaLlegada: _fechaLlegada,
      tipoCambio: double.parse(_tipoCambioCtrl.text),
      notas: _notasCtrl.text.trim(),
      usaImpuestosGlobales: _usaImpuestosGlobales,
      gaGlobalPct: double.parse(_gaGlobalCtrl.text),
      ivaGlobalPct: double.parse(_ivaGlobalCtrl.text),
      porcentajeDeclaracion: double.parse(_pctDeclaracionCtrl.text),
      fleteEstimadoUsd: double.parse(_fleteUsdCtrl.text),
      despachanteEstimadoBs: double.parse(_despachanteBsCtrl.text),
      documentacionEstimadaBs: double.parse(_docBsCtrl.text),
      almacenajeEstimadoBs: double.parse(_almBsCtrl.text),
    );

    final ok = await context.read<ImportacionesService>().crearCarpeta(nuevaCarpeta);
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carpeta abierta. Agrega tus ítems ahora.'), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Importación', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.importacionesColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('1. Logística y Fechas', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.importacionesColor, fontSize: 16)),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [ 
                  Expanded(flex: 2, child: TextFormField(controller: _despachoCtrl, decoration: const InputDecoration(labelText: 'Ref / Despacho'), validator: (v) => v!.isEmpty ? 'Req' : null)), 
                  const SizedBox(width: 16), 
                  Expanded(flex: 1, child: DropdownButtonFormField<String>(
                    value: _incoterm, 
                    decoration: const InputDecoration(labelText: 'Incoterm'), 
                    items: ['FOB', 'CIF', 'EXW'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), 
                    onChanged: (v) => setState(() {
                      _incoterm = v!;
                      if (_incoterm == 'CIF') _fleteUsdCtrl.text = '0'; // En CIF el flete es 0
                    })
                  )) 
                ]
              ),
              const SizedBox(height: 8),
              Text(_obtenerMensajeIncoterm(), style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Row(
                children: [ 
                  Expanded(child: TextFormField(controller: _proveedorCtrl, decoration: const InputDecoration(labelText: 'Proveedor'), validator: (v) => v!.isEmpty ? 'Req' : null)), 
                  const SizedBox(width: 16), 
                  Expanded(child: TextFormField(controller: _tipoCambioCtrl, decoration: const InputDecoration(labelText: 'TC Oficial (Bs/\$)'))) 
                ]
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: InkWell(onTap: () => _seleccionarFecha(context, true), child: InputDecorator(decoration: const InputDecoration(labelText: 'Salida de Origen (ETD)'), child: Text(_fechaEmbarque != null ? _dateFormat.format(_fechaEmbarque!) : 'Seleccionar', style: TextStyle(color: _fechaEmbarque != null ? Colors.black : Colors.grey))))),
                  const SizedBox(width: 16),
                  Expanded(child: InkWell(onTap: () => _seleccionarFecha(context, false), child: InputDecorator(decoration: const InputDecoration(labelText: 'Llegada a Destino (ETA)'), child: Text(_fechaLlegada != null ? _dateFormat.format(_fechaLlegada!) : 'Seleccionar', style: TextStyle(color: _fechaLlegada != null ? Colors.black : Colors.grey))))),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text('2. Estrategia Aduanera', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.importacionesColor, fontSize: 16)),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(controller: _pctDeclaracionCtrl, decoration: const InputDecoration(labelText: '% Declarado en Aduana (Base Imponible)', suffixText: '%', hintText: 'Ej: 60 si facturan por menos')),
              const SizedBox(height: 16),
              SwitchListTile(title: const Text('Usar Arancel % Global para todos los ítems'), contentPadding: EdgeInsets.zero, value: _usaImpuestosGlobales, activeColor: AppColors.importacionesColor, onChanged: (v) => setState(() => _usaImpuestosGlobales = v)),
              if (_usaImpuestosGlobales) ...[
                const SizedBox(height: 16),
                Row(
                  children: [ 
                    Expanded(child: TextFormField(controller: _gaGlobalCtrl, decoration: const InputDecoration(labelText: 'Arancel GA %'))), 
                    const SizedBox(width: 16), 
                    Expanded(child: TextFormField(controller: _ivaGlobalCtrl, decoration: const InputDecoration(labelText: 'IVA Importación %'))) 
                  ]
                ),
              ],

              const SizedBox(height: 32),
              const Text('3. Estimaciones Iniciales (Proforma)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.importacionesColor, fontSize: 16)),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [ 
                  Expanded(child: TextFormField(controller: _fleteUsdCtrl, decoration: const InputDecoration(labelText: 'Flete Marítimo/Aéreo', prefixText: '\$US '))), 
                  const SizedBox(width: 16), 
                  Expanded(child: TextFormField(controller: _despachanteBsCtrl, decoration: const InputDecoration(labelText: 'Despachante', prefixText: 'Bs. '))) 
                ]
              ),
              const SizedBox(height: 16),
              Row(
                children: [ 
                  Expanded(child: TextFormField(controller: _docBsCtrl, decoration: const InputDecoration(labelText: 'Documentación', prefixText: 'Bs. '))), 
                  const SizedBox(width: 16), 
                  Expanded(child: TextFormField(controller: _almBsCtrl, decoration: const InputDecoration(labelText: 'Almacenaje', prefixText: 'Bs. '))) 
                ]
              ),
              
              const SizedBox(height: 32),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppColors.importacionesColor, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)), onPressed: _isSaving ? null : _crearCarpeta, icon: const Icon(Icons.save), label: Text(_isSaving ? 'Guardando...' : 'Crear Carpeta e Ingresar Ítems')),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
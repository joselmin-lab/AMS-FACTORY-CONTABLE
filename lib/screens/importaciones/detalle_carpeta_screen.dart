import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/services/importaciones_service.dart';
import 'package:ams_control_contable/services/supabase_service.dart';

class DetalleCarpetaScreen extends StatefulWidget {
  final String carpetaId;
  const DetalleCarpetaScreen({super.key, required this.carpetaId});

  @override
  State<DetalleCarpetaScreen> createState() => _DetalleCarpetaScreenState();
}

class _DetalleCarpetaScreenState extends State<DetalleCarpetaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyBs = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _currencyUsd = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
  bool _isProcesando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Ahora son 4 pestañas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImportacionesService>().fetchCarpetas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 1. BUSCADOR DE INVENTARIO (AHORA TRAE LA UNIDAD)
  Future<List<Map<String, dynamic>>> _buscarEnInventario(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await SupabaseService.client
          .from('inventario')
          .select('id, codigo, nombre, categoria, origen, unidad')
          .ilike('nombre', '%$query%')
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error buscando inventario: $e');
      return [];
    }
  }

  // 2. DIÁLOGO DE ÍTEMS
  void _mostrarDialogoItem(ImpCarpeta carpeta) {
    if (carpeta.estado == 'Liquidada') return;

    final formKey = GlobalKey<FormState>();
    final cantidadCtrl = TextEditingController();
    final pesoCtrl = TextEditingController(text: '0');
    final fobUsdCtrl = TextEditingController();
    Map<String, dynamic>? itemSeleccionado;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Agregar Ítem', style: TextStyle(fontSize: 18, color: AppColors.importacionesColor)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (item) => '[${item['codigo']}] ${item['nombre']} (${item['unidad'] ?? 'Unid'})',
                    optionsBuilder: (textEditingValue) async {
                      if (textEditingValue.text.length < 2) return const Iterable<Map<String, dynamic>>.empty();
                      return await _buscarEnInventario(textEditingValue.text);
                    },
                    onSelected: (selection) => itemSeleccionado = selection,
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Buscar Producto', prefixIcon: Icon(Icons.search_rounded)),
                        validator: (v) => itemSeleccionado == null ? 'Seleccione del listado' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: cantidadCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad'), validator: (v) => v!.isEmpty ? 'Req' : null)),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: pesoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Peso/Vol (Kg)'))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: fobUsdCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio FOB USD', prefixText: '\$ '), validator: (v) => v!.isEmpty ? 'Req' : null),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && itemSeleccionado != null) {
                final nombreConUnidad = "${itemSeleccionado!['nombre']} (${itemSeleccionado!['unidad'] ?? 'Unid'})";
                final nuevoItem = ImpItem(producto: nombreConUnidad, cantidad: double.parse(cantidadCtrl.text), pesoTotal: double.parse(pesoCtrl.text), precioFobUsd: double.parse(fobUsdCtrl.text));
                
                Navigator.pop(ctx);
                try {
                  final mapa = nuevoItem.toJson();
                  mapa['carpeta_id'] = carpeta.id;
                  await SupabaseService.client.from('imp_items').insert(mapa);
                  if (mounted) context.read<ImportacionesService>().fetchCarpetas();
                } catch(e) {
                  debugPrint(e.toString());
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // 3. DIÁLOGO DE GASTOS (CON MONEDA)
  void _mostrarDialogoGasto(ImpCarpeta carpeta) {
    if (carpeta.estado == 'Liquidada') return;

    final formKey = GlobalKey<FormState>();
    final proveedorCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final tcCtrl = TextEditingController(text: carpeta.tipoCambio.toString());
    
    String moneda = 'Bs';
    bool esCapitalizable = true;
    bool tieneIva = false;
    String metodoProrrateo = 'Valor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Registrar Gasto', style: TextStyle(color: AppColors.importacionesColor)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: proveedorCtrl, decoration: const InputDecoration(labelText: 'Proveedor'), validator: (v) => v!.isEmpty ? 'Req' : null)),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Concepto (Ej: Flete)'), validator: (v) => v!.isEmpty ? 'Req' : null)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: moneda,
                              decoration: const InputDecoration(labelText: 'Moneda'),
                              items: ['Bs', 'USD'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setStateDialog(() => moneda = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(controller: montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto Original'), validator: (v) => v!.isEmpty ? 'Req' : null),
                          ),
                        ],
                      ),
                      if (moneda == 'USD') ...[
                        const SizedBox(height: 16),
                        TextFormField(controller: tcCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tipo de Cambio (Bs/\$)')),
                      ],
                      const Divider(height: 32),
                      SwitchListTile(
                        title: const Text('¿Suma al costo del producto?', style: TextStyle(fontSize: 13)),
                        subtitle: const Text('Aranceles y Fletes SI. Multas NO.', style: TextStyle(fontSize: 11)),
                        value: esCapitalizable,
                        onChanged: (v) => setStateDialog(() => esCapitalizable = v),
                      ),
                      SwitchListTile(
                        title: const Text('¿Tiene Factura Local (IVA)?', style: TextStyle(fontSize: 13)),
                        subtitle: const Text('Se separará el IVA para crédito fiscal.', style: TextStyle(fontSize: 11)), // <-- TEXTO DEL 14.94% QUITADO
                        value: tieneIva,
                        onChanged: (v) => setStateDialog(() => tieneIva = v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: metodoProrrateo,
                        decoration: const InputDecoration(labelText: 'Prorratear Costo por:'),
                        items: ['Valor', 'Peso', 'Cantidad'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setStateDialog(() => metodoProrrateo = v!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final original = double.parse(montoCtrl.text);
                    final tc = moneda == 'USD' ? double.parse(tcCtrl.text) : 1.0;
                    final totalBs = original * tc;

                    final nuevoGasto = ImpGasto(
                      proveedor: proveedorCtrl.text.trim(),
                      descripcion: descCtrl.text.trim(),
                      moneda: moneda,
                      montoOriginal: original,
                      tipoCambio: tc,
                      montoBs: totalBs,
                      esCapitalizable: esCapitalizable,
                      tieneIva: tieneIva,
                      metodoProrrateo: metodoProrrateo,
                      fechaGasto: DateTime.now(),
                    );
                    
                    Navigator.pop(ctx);
                    await context.read<ImportacionesService>().agregarGasto(carpeta.id!, nuevoGasto);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        }
      ),
    );
  }

  // 4. DIÁLOGO DE PAGOS (ANTICIPOS)
  void _mostrarDialogoPago(ImpCarpeta carpeta) {
    if (carpeta.estado == 'Liquidada') return;

    final formKey = GlobalKey<FormState>();
    final conceptoCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final tcCtrl = TextEditingController(text: carpeta.tipoCambio.toString());
    String moneda = 'USD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Registrar Pago (Salida)', style: TextStyle(color: Colors.redAccent)),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Este pago descontará dinero real de la Caja (Salidas Extra)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextFormField(controller: conceptoCtrl, decoration: const InputDecoration(labelText: 'Concepto (Ej: Anticipo 30% Fábrica)'), validator: (v) => v!.isEmpty ? 'Req' : null),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: moneda,
                            decoration: const InputDecoration(labelText: 'Moneda'),
                            items: ['USD', 'Bs'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (v) => setStateDialog(() => moneda = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(controller: montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto Pagado'), validator: (v) => v!.isEmpty ? 'Req' : null),
                        ),
                      ],
                    ),
                    if (moneda == 'USD') ...[
                      const SizedBox(height: 16),
                      TextFormField(controller: tcCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'TC del Día (Para contabilidad en Bs)')),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final original = double.parse(montoCtrl.text);
                    final tc = moneda == 'USD' ? double.parse(tcCtrl.text) : 1.0;
                    final totalBs = original * tc;

                    final pago = ImpPago(
                      concepto: conceptoCtrl.text.trim(),
                      moneda: moneda,
                      montoOriginal: original,
                      tipoCambio: tc,
                      montoBs: totalBs,
                      fecha: DateTime.now(),
                    );
                    
                    Navigator.pop(ctx);
                    final ok = await context.read<ImportacionesService>().agregarPago(carpeta.id!, carpeta, pago);
                    if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago Registrado y enviado a Salidas.'), backgroundColor: Colors.green));
                  }
                },
                child: const Text('Registrar Pago'),
              ),
            ],
          );
        }
      ),
    );
  }

  // 5. ACCIONES PRINCIPALES
  void _liquidar(ImpCarpeta carpeta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liquidar Importación'),
        content: const Text('El sistema prorrateará los gastos y fijará el costo final de inventario. Irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcesando = true);
              await context.read<ImportacionesService>().liquidarCarpeta(carpeta.id!);
              setState(() => _isProcesando = false);
            },
            child: const Text('Liquidar'),
          ),
        ],
      ),
    );
  }

  void _eliminarCarpeta() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Carpeta', style: TextStyle(color: Colors.red)),
        content: const Text('¿Estás seguro? Se borrará todo el historial de la importación y se revertirán los pagos de las salidas de caja.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcesando = true);
              final ok = await context.read<ImportacionesService>().eliminarCarpeta(widget.carpetaId);
              setState(() => _isProcesando = false);
              if (ok && mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImportacionesService>(
      builder: (context, service, _) {
        final carpetas = service.carpetas.where((c) => c.id == widget.carpetaId).toList();
        if (carpetas.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final carpeta = carpetas.first;
        final esLiquidada = carpeta.estado == 'Liquidada';

        // Cálculos para el resumen
        final double fobUsdItems = carpeta.items.fold(0, (sum, i) => sum + i.totalFobUsd);
        final double fobBsItems = fobUsdItems * carpeta.tipoCambio;
        final double gastosEstimadosBs = carpeta.fleteEstimado + carpeta.aduanaEstimada + carpeta.otrosGastosEstimados;
        final double costoProyectadoBs = fobBsItems + gastosEstimadosBs;

        return Scaffold(
          appBar: AppBar(
            title: Text(carpeta.numeroDespacho, style: const TextStyle(color: Colors.white)),
            backgroundColor: esLiquidada ? Colors.green.shade800 : AppColors.importacionesColor,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (!esLiquidada) IconButton(icon: const Icon(Icons.delete_rounded), onPressed: _eliminarCarpeta, tooltip: 'Eliminar Carpeta'),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Resumen'),
                Tab(text: 'Ítems'),
                Tab(text: 'Gastos'),
                Tab(text: 'Pagos (Caja)'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // PESTAÑA 1: RESUMEN
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: esLiquidada ? Colors.green.shade50 : AppColors.importacionesColor.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text(carpeta.estado.toUpperCase(), style: TextStyle(color: esLiquidada ? Colors.green.shade700 : AppColors.importacionesColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total FOB:'), Text(_currencyUsd.format(esLiquidada ? carpeta.totalFobUsd : fobUsdItems))]),
                        if (!esLiquidada) ...[
                          const SizedBox(height: 16),
                          const Text('PROYECCIÓN VS REALIDAD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Costo Gastos (Estimado):'), Text(_currencyBs.format(gastosEstimadosBs), style: const TextStyle(color: Colors.orange))]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Costo Landed (Proyectado):'), Text(_currencyBs.format(costoProyectadoBs), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange))]),
                        ],
                        if (esLiquidada) ...[
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Gastos Reales Capitalizados:'), Text(_currencyBs.format(carpeta.totalGastosBs), style: const TextStyle(color: Colors.red))]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('COSTO LANDED FINAL:'), Text(_currencyBs.format(carpeta.costoTotalBs), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green))]),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!esLiquidada)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _isProcesando ? null : () => _liquidar(carpeta),
                      icon: _isProcesando ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.calculate_rounded),
                      label: Text(_isProcesando ? 'Procesando...' : 'LIQUIDAR Y FIJAR COSTOS'),
                    ),
                ],
              ),

              // PESTAÑA 2: ÍTEMS
              Scaffold(
                body: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: carpeta.items.length,
                  itemBuilder: (ctx, i) {
                    final item = carpeta.items[i];
                    return Card(
                      child: ListTile(
                        title: Text(item.producto, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Cant: ${item.cantidad} | Peso: ${item.pesoTotal} | FOB: ${_currencyUsd.format(item.precioFobUsd)}'),
                        trailing: esLiquidada ? Text(_currencyBs.format(item.costoUnitarioBs), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) : null,
                      ),
                    );
                  },
                ),
                floatingActionButton: esLiquidada ? null : FloatingActionButton(onPressed: () => _mostrarDialogoItem(carpeta), child: const Icon(Icons.add)),
              ),

              // PESTAÑA 3: GASTOS
              Scaffold(
                body: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: carpeta.gastos.length,
                  itemBuilder: (ctx, i) {
                    final gasto = carpeta.gastos[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: const Icon(Icons.receipt, color: Colors.red)),
                        title: Text(gasto.descripcion),
                        subtitle: Text('${gasto.proveedor} | ${gasto.moneda} ${gasto.montoOriginal} (TC: ${gasto.tipoCambio})'),
                        trailing: Text(_currencyBs.format(gasto.montoBs), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
                floatingActionButton: esLiquidada ? null : FloatingActionButton.extended(onPressed: () => _mostrarDialogoGasto(carpeta), backgroundColor: Colors.redAccent, label: const Text('Gasto', style: TextStyle(color: Colors.white)), icon: const Icon(Icons.add, color: Colors.white)),
              ),

              // PESTAÑA 4: PAGOS (ANTICIPOS)
              Scaffold(
                body: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: carpeta.pagos.length,
                  itemBuilder: (ctx, i) {
                    final pago = carpeta.pagos[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.payments, color: Colors.white)),
                        title: Text(pago.concepto),
                        subtitle: Text('Pagado: ${pago.moneda} ${pago.montoOriginal} (TC: ${pago.tipoCambio})\nFecha: ${DateFormat('dd/MM/yyyy').format(pago.fecha)}'),
                        trailing: Text('- ${_currencyBs.format(pago.montoBs)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                    );
                  },
                ),
                floatingActionButton: esLiquidada ? null : FloatingActionButton.extended(onPressed: () => _mostrarDialogoPago(carpeta), backgroundColor: Colors.blue, label: const Text('Pago', style: TextStyle(color: Colors.white)), icon: const Icon(Icons.add, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
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
  final _curBs = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _curUsd = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  // --- DIÁLOGO ÍTEMS (Con espacios y Scroll) ---
  void _dialogoItem(ImpCarpeta carpeta, {ImpItem? item}) {
    if (carpeta.estado == 'Liquidada') return;
    final fKey = GlobalKey<FormState>();
    final cantC = TextEditingController(text: item?.cantidad.toString() ?? '');
    final pesoC = TextEditingController(text: item?.pesoTotal.toString() ?? '0');
    final fobC = TextEditingController(text: item?.precioFobUsd.toString() ?? '');
    final gaC = TextEditingController(text: item?.gaPct.toString() ?? carpeta.gaGlobalPct.toString());
    final ivaC = TextEditingController(text: item?.ivaPct.toString() ?? carpeta.ivaGlobalPct.toString());
    Map<String, dynamic>? sel;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item == null ? 'Nuevo Ítem' : 'Editar Ítem'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: fKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item == null)
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (o) => '[${o['codigo']}] ${o['nombre']} (${o['unidad'] ?? 'Unid'})',
                      optionsBuilder: (tv) async {
                        if (tv.text.length < 2) return const Iterable.empty();
                        final res = await SupabaseService.client.from('inventario').select('id, codigo, nombre, unidad').ilike('nombre', '%${tv.text}%').limit(10);
                        return List<Map<String, dynamic>>.from(res);
                      },
                      onSelected: (s) => sel = s,
                      fieldViewBuilder: (_, c, fn, __) => TextFormField(controller: c, focusNode: fn, decoration: const InputDecoration(labelText: 'Buscar Producto (Inventario)'), validator: (v) => sel == null ? 'Req' : null),
                    )
                  else Text(item.producto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  
                  const SizedBox(height: 16),
                  Row(children: [ Expanded(child: TextFormField(controller: cantC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad'), validator: (v) => v!.isEmpty?'Req':null)), const SizedBox(width: 16), Expanded(child: TextFormField(controller: pesoC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Peso/Volumen (Kg)'))) ]),
                  const SizedBox(height: 16),
                  TextFormField(controller: fobC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio FOB Unitario', prefixText: '\$US '), validator: (v) => v!.isEmpty?'Req':null),
                  
                  if (!carpeta.usaImpuestosGlobales) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Impuestos Específicos', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [ Expanded(child: TextFormField(controller: gaC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Arancel (GA) %'))), const SizedBox(width: 16), Expanded(child: TextFormField(controller: ivaC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'IVA Importación %'))) ]),
                  ]
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (item != null) TextButton(onPressed: () async { Navigator.pop(ctx); await SupabaseService.client.from('imp_items').delete().eq('id', item.id!); await context.read<ImportacionesService>().recalcularImpuestosAutomaticos(carpeta.id!); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (fKey.currentState!.validate()) {
              final nuevo = ImpItem(id: item?.id, inventarioId: item?.inventarioId ?? sel?['id']?.toString(), producto: item?.producto ?? "${sel!['nombre']} (${sel!['unidad'] ?? 'Unid'})", cantidad: double.parse(cantC.text), pesoTotal: double.parse(pesoC.text), precioFobUsd: double.parse(fobC.text), gaPct: double.parse(gaC.text), ivaPct: double.parse(ivaC.text));
              Navigator.pop(ctx);
              final map = nuevo.toJson();
              if (item == null) { map['carpeta_id'] = carpeta.id; await SupabaseService.client.from('imp_items').insert(map); } 
              else { await SupabaseService.client.from('imp_items').update(map).eq('id', item.id!); }
              await context.read<ImportacionesService>().recalcularImpuestosAutomaticos(carpeta.id!);
            }
          }, child: const Text('Guardar')),
        ],
      ),
    );
  }

  // --- DIÁLOGO GASTOS (Con selector de moneda y espacios) ---
  void _dialogoGasto(ImpCarpeta carpeta, {ImpGasto? gasto}) {
    if (carpeta.estado == 'Liquidada') return;
    if (gasto != null && (gasto.tipoSistema == 'GA' || gasto.tipoSistema == 'IVA')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este impuesto se calcula automáticamente según los ítems y tu % de declaración.'), backgroundColor: Colors.orange));
      return;
    }

    final fKey = GlobalKey<FormState>();
    final provC = TextEditingController(text: gasto?.proveedor ?? '');
    final descC = TextEditingController(text: gasto?.descripcion ?? '');
    final montC = TextEditingController(text: gasto?.montoOriginal.toString() ?? '');
    final tC = TextEditingController(text: gasto?.tipoCambio.toString() ?? carpeta.tipoCambio.toString());
    
    String monedaSeleccionada = gasto?.moneda ?? 'Bs';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(gasto == null ? 'Nuevo Gasto' : 'Editar Gasto Operativo'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: fKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gasto?.tipoSistema != null)
                      Container(padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 16), color: Colors.blue.shade50, child: const Text('Gasto Base del Sistema. Puedes ajustar los montos reales facturados.', style: TextStyle(color: Colors.blue, fontSize: 12))),
                    
                    TextFormField(controller: provC, decoration: const InputDecoration(labelText: 'Proveedor (Ej: Aduana, Naviera)'), enabled: gasto?.tipoSistema == null),
                    const SizedBox(height: 16),
                    TextFormField(controller: descC, decoration: const InputDecoration(labelText: 'Concepto (Ej: Flete Marítimo)'), enabled: gasto?.tipoSistema == null),
                    const SizedBox(height: 16),
                    Row(
                      children: [ 
                        Expanded(flex: 1, child: DropdownButtonFormField<String>(
                          value: monedaSeleccionada,
                          decoration: const InputDecoration(labelText: 'Moneda'),
                          items: const [DropdownMenuItem(value: 'Bs', child: Text('Bs')), DropdownMenuItem(value: 'USD', child: Text('USD'))],
                          onChanged: gasto?.tipoSistema != null ? null : (v) => setStateDialog(() => monedaSeleccionada = v!),
                        )), 
                        const SizedBox(width: 16), 
                        Expanded(flex: 2, child: TextFormField(controller: montC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto Original'))) 
                      ]
                    ),
                    if (monedaSeleccionada == 'USD') ...[
                      const SizedBox(height: 16),
                      TextFormField(controller: tC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'TC Oficial de Pago (Bs/\$)')),
                    ]
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (gasto != null && gasto.tipoSistema == null) TextButton(onPressed: () { Navigator.pop(ctx); context.read<ImportacionesService>().eliminarGasto(gasto.id!); }, child: const Text('Eliminar Gasto', style: TextStyle(color: Colors.red))),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () async {
              if (fKey.currentState!.validate()) {
                final orig = double.parse(montC.text);
                final tcReal = monedaSeleccionada == 'USD' ? double.parse(tC.text) : 1.0;
                final bs = orig * tcReal;
                final nuevo = ImpGasto(id: gasto?.id, proveedor: provC.text, descripcion: descC.text, moneda: monedaSeleccionada, montoOriginal: orig, tipoCambio: tcReal, montoBs: bs, esCapitalizable: gasto?.esCapitalizable ?? true, tieneIva: gasto?.tieneIva ?? false, metodoProrrateo: gasto?.metodoProrrateo ?? 'Valor', fechaGasto: gasto?.fechaGasto ?? DateTime.now(), tipoSistema: gasto?.tipoSistema);
                Navigator.pop(ctx);
                await context.read<ImportacionesService>().guardarGasto(carpeta.id!, nuevo);
              }
            }, child: const Text('Guardar Gasto')),
          ],
        ),
      ),
    );
  }

      // --- DIÁLOGO PAGOS (Glosa Automática y Saldos Dinámicos) ---
  void _dialogoPago(ImpCarpeta carpeta) {
    if (carpeta.estado == 'Liquidada') return;
    final fKey = GlobalKey<FormState>();
    final mC = TextEditingController();
    final tcC = TextEditingController(text: carpeta.tipoCambio.toString());
    
    ImpGasto? gastoSel;
    String mon = 'USD'; 
    String infoSaldo = ''; // Aquí guardaremos el texto del saldo

    // Función interna para calcular cuánto debemos
    void _actualizarSaldo() {
      if (gastoSel == null) {
        // Deuda a la Fábrica (FOB)
        final double fobUsdTotal = carpeta.items.fold(0.0, (s, i) => s + i.totalFobUsd);
        final double pagadoUsd = carpeta.pagos.where((p) => p.gastoId == null).fold(0.0, (s, p) => s + (p.moneda == 'USD' ? p.montoOriginal : p.montoBs / carpeta.tipoCambio));
        final double saldo = fobUsdTotal - pagadoUsd;
        infoSaldo = 'Deuda Total: \$US ${_curUsd.format(fobUsdTotal).replaceAll('\$', '')}\nPagado: \$US ${_curUsd.format(pagadoUsd).replaceAll('\$', '')}\nSALDO PENDIENTE: \$US ${_curUsd.format(saldo > 0 ? saldo : 0).replaceAll('\$', '')}';
      } else {
        // Deuda de un Gasto Operativo
        final double totalGasto = gastoSel!.montoOriginal;
        final double pagadoGasto = carpeta.pagos.where((p) => p.gastoId == gastoSel!.id).fold(0.0, (s, p) => s + (p.moneda == gastoSel!.moneda ? p.montoOriginal : (gastoSel!.moneda == 'USD' ? p.montoBs / carpeta.tipoCambio : p.montoBs)));
        final double saldo = totalGasto - pagadoGasto;
        infoSaldo = 'Deuda Total: ${gastoSel!.moneda} ${_curBs.format(totalGasto).replaceAll('Bs.', '').trim()}\nPagado: ${gastoSel!.moneda} ${_curBs.format(pagadoGasto).replaceAll('Bs.', '').trim()}\nSALDO PENDIENTE: ${gastoSel!.moneda} ${_curBs.format(saldo > 0 ? saldo : 0).replaceAll('Bs.', '').trim()}';
      }
    }

    _actualizarSaldo(); // Calcular el saldo inicial para la Fábrica

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar Pago a Proveedor'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Form(
                key: fKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(labelText: '¿A quién le estamos pagando?'),
                      value: null,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Fábrica Mercadería (FOB)', style: TextStyle(fontWeight: FontWeight.bold))),
                        ...carpeta.gastos.map((g) => DropdownMenuItem(value: g.id, child: Text('${g.descripcion} (${g.moneda})')))
                      ],
                      onChanged: (v) {
                        setS(() {
                          if (v == null) { gastoSel = null; mon = 'USD'; } 
                          else { gastoSel = carpeta.gastos.firstWhere((g) => g.id == v); mon = gastoSel!.moneda; }
                          _actualizarSaldo(); // Recalcular el saldo al cambiar de opción
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // CAJA INFORMATIVA DE SALDO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(infoSaldo, style: const TextStyle(color: Colors.blue, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [ 
                        Text('Moneda: $mon', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)), 
                        const SizedBox(width: 24), 
                        Expanded(child: TextFormField(controller: mC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto Pagado'), validator: (v) => v!.isEmpty ? 'Req' : null)) 
                      ]
                    ),
                    if (mon == 'USD') ...[
                      const SizedBox(height: 16),
                      TextFormField(controller: tcC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'TC del Día (Para Caja Bs)')),
                    ]
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () async {
              if (fKey.currentState!.validate()) {
                // Reemplazamos comas por puntos por si el teclado las inserta mal
                final origStr = mC.text.replaceAll(',', '.');
                final tcStr = tcC.text.replaceAll(',', '.');
                
                final orig = double.tryParse(origStr) ?? 0.0;
                final tcReal = mon == 'USD' ? (double.tryParse(tcStr) ?? 1.0) : 1.0;
                
                if (orig <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un monto válido.'), backgroundColor: Colors.orange));
                  return;
                }

                // AQUÍ CREAMOS LA GLOSA AUTOMÁTICA
                final String glosaAutomatica = 'Pago Carpeta Imp. #${carpeta.numeroDespacho} - ${gastoSel == null ? "FOB Fábrica" : "Gasto: " + gastoSel!.descripcion}';

                final bs = orig * tcReal;
                final p = ImpPago(gastoId: gastoSel?.id, concepto: glosaAutomatica, moneda: mon, montoOriginal: orig, tipoCambio: tcReal, montoBs: bs, fecha: DateTime.now());
                
                Navigator.pop(ctx); // Cerramos el diálogo primero para evitar bloqueos
                
                final ok = await context.read<ImportacionesService>().agregarPago(carpeta.id!, carpeta, p);
                
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago Registrado y Descontado de Caja'), backgroundColor: Colors.green));
                } else if (mounted) {
                  final err = context.read<ImportacionesService>().error;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar pago: $err'), backgroundColor: Colors.red));
                }
              }
            }, child: const Text('Pagar y Descontar de Caja')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImportacionesService>(
      builder: (ctx, srv, _) {
        final cars = srv.carpetas.where((c) => c.id == widget.carpetaId).toList();
        if (cars.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final carpeta = cars.first;
        final liq = carpeta.estado == 'Liquidada';

        return Scaffold(
          appBar: AppBar(title: Text('${carpeta.numeroDespacho} - ${carpeta.incoterm}'), backgroundColor: liq ? Colors.green.shade800 : AppColors.importacionesColor, actions: [ if (!liq) IconButton(icon: const Icon(Icons.delete), onPressed: () { srv.eliminarCarpeta(carpeta.id!); Navigator.pop(context); }) ], bottom: TabBar(controller: _tabController, isScrollable: true, tabs: const [Tab(text: 'Resumen Financiero'), Tab(text: 'Ítems de Inventario'), Tab(text: 'Gastos Operativos'), Tab(text: 'Pagos Realizados')])),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. RESUMEN
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('VALOR DE LA MERCADERÍA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Comercial (FOB Real):'), Text(_curUsd.format(carpeta.items.fold(0.0, (s,i)=>s+i.totalFobUsd)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base Imponible Aduana (${carpeta.porcentajeDeclaracion}%):'), Text(_curUsd.format(carpeta.items.fold(0.0, (s,i)=>s+i.totalFobUsd) * (carpeta.porcentajeDeclaracion/100)))]),
                  ])),
                  const SizedBox(height: 16),
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('GASTOS OPERATIVOS REGISTRADOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const Divider(),
                    ...carpeta.gastos.map((g) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(g.descripcion), Text(_curBs.format(g.montoBs))]))),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('COSTO LANDED TOTAL (FOB + GASTOS):'), Text(_curBs.format((carpeta.items.fold(0.0, (s,i)=>s+i.totalFobUsd)*carpeta.tipoCambio) + carpeta.gastos.fold(0.0, (s,g)=>s+g.montoBs)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                  ])),
                  const SizedBox(height: 24),
                  if (!liq) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.all(16), foregroundColor: Colors.white), onPressed: () => srv.liquidarCarpeta(carpeta.id!), icon: const Icon(Icons.inventory_rounded), label: const Text('LIQUIDAR IMPORTACIÓN (Inyectar Stock)'))
                ],
              ),
              // 2. ITEMS
              Scaffold(
                body: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: carpeta.items.length, itemBuilder: (_, i) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(title: Text(carpeta.items[i].producto, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Cantidad: ${carpeta.items[i].cantidad} | FOB Unitario: \$US ${carpeta.items[i].precioFobUsd}\nImpuestos: GA ${carpeta.items[i].gaPct}% - IVA ${carpeta.items[i].ivaPct}%'), trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _dialogoItem(carpeta, item: carpeta.items[i]))))),
                floatingActionButton: FloatingActionButton.extended(onPressed: () => _dialogoItem(carpeta), label: const Text('Agregar Ítem'), icon: const Icon(Icons.add)),
              ),
              // 3. GASTOS
              Scaffold(
                body: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: carpeta.gastos.length, itemBuilder: (_, i) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: CircleAvatar(backgroundColor: carpeta.gastos[i].tipoSistema != null ? Colors.blue.shade100 : Colors.orange.shade100, child: Icon(carpeta.gastos[i].tipoSistema != null ? Icons.settings_suggest : Icons.receipt_long, color: carpeta.gastos[i].tipoSistema != null ? Colors.blue : Colors.orange)), title: Text(carpeta.gastos[i].descripcion, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${carpeta.gastos[i].proveedor}\nMoneda: ${carpeta.gastos[i].moneda} ${carpeta.gastos[i].montoOriginal} (TC: ${carpeta.gastos[i].tipoCambio})'), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [ Text(_curBs.format(carpeta.gastos[i].montoBs), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), InkWell(onTap: () => _dialogoGasto(carpeta, gasto: carpeta.gastos[i]), child: const Text('Editar', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))) ])))),
                floatingActionButton: FloatingActionButton.extended(onPressed: () => _dialogoGasto(carpeta), backgroundColor: Colors.redAccent, label: const Text('Gasto Extra', style: TextStyle(color: Colors.white)), icon: const Icon(Icons.add, color: Colors.white)),
              ),
              // 4. PAGOS
              Scaffold(
                body: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: carpeta.pagos.length, itemBuilder: (_, i) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.payments, color: Colors.white)), title: Text(carpeta.pagos[i].concepto, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Destino: ${carpeta.pagos[i].gastoId == null ? "Fábrica" : "Gasto Operativo"}\nPagado: ${carpeta.pagos[i].moneda} ${carpeta.pagos[i].montoOriginal} (TC: ${carpeta.pagos[i].tipoCambio})'), trailing: Text('- ${_curBs.format(carpeta.pagos[i].montoBs)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))))),
                floatingActionButton: FloatingActionButton.extended(onPressed: () => _dialogoPago(carpeta), backgroundColor: Colors.green, label: const Text('Registrar Salida / Pago', style: TextStyle(color: Colors.white)), icon: const Icon(Icons.add, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
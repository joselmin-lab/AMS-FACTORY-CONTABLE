import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // IMPORTANTE: Agregado para inicializar idiomas
import 'package:ams_control_contable/services/salidas_service.dart';
import 'package:ams_control_contable/services/cuentas_cobrar_service.dart';
import 'package:ams_control_contable/services/cuentas_pagar_service.dart';
import 'package:ams_control_contable/services/gastos_service.dart';
import 'package:ams_control_contable/services/usuarios_service.dart';
import 'package:ams_control_contable/services/ingresos_service.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/compras_service.dart';
import 'services/ventas_service.dart';
import 'services/importaciones_service.dart';
import 'services/impositivo_service.dart';



const _supabaseUrl = 'https://tjqjfncersdbarscfdph.supabase.co'; 
const _supabaseAnonKey = 'sb_publishable_OM4Px73jt62TTrADqlXFGQ_swS6zV7c';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // INICIALIZAR INTL PARA LAS FECHAS Y MONEDAS EN BOLIVIA
  await initializeDateFormatting('es_BO', null);
  
  // Inicializar Supabase
  await SupabaseService.initialize(
    supabaseUrl: _supabaseUrl,
    supabaseAnonKey: _supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComprasService()),
        ChangeNotifierProvider(create: (_) => VentasService()),
        ChangeNotifierProvider(create: (_) => ImportacionesService()),
        ChangeNotifierProvider(create: (_) => SalidasService()),
        ChangeNotifierProvider(create: (_) => ImpositivoService()),
        ChangeNotifierProvider(create: (_) => CuentasCobrarService()),
        ChangeNotifierProvider(create: (_) => CuentasPagarService()),
        ChangeNotifierProvider(create: (_) => GastosService()),
        ChangeNotifierProvider(create: (_) => UsuariosService()),
        ChangeNotifierProvider(create: (_) => IngresosService()),
        ChangeNotifierProvider(create: (_) => ImportacionesService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMS Control Contable',
      theme: AppTheme.lightTheme,
      initialRoute: SupabaseService.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
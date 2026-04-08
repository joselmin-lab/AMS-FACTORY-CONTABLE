import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/core/theme/app_theme.dart';
import 'package:ams_control_contable/services/compras_service.dart';
import 'package:ams_control_contable/services/importaciones_service.dart';
import 'package:ams_control_contable/services/ventas_service.dart';

// ---------------------------------------------------------------------------
// Supabase configuration
// Replace these values with your actual Supabase project URL and anon key.
// For production, load these from environment variables or a .env file and
// never commit secrets to source control.
// ---------------------------------------------------------------------------
const String _supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const String _supabaseAnonKey = 'YOUR_ANON_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uncomment the following block once you have your Supabase credentials:
  //
  // await SupabaseService.initialize(
  //   supabaseUrl: _supabaseUrl,
  //   supabaseAnonKey: _supabaseAnonKey,
  // );

  runApp(const AmsControlContableApp());
}

class AmsControlContableApp extends StatelessWidget {
  const AmsControlContableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComprasService()),
        ChangeNotifierProvider(create: (_) => VentasService()),
        ChangeNotifierProvider(create: (_) => ImportacionesService()),
      ],
      child: MaterialApp(
        title: 'AMS Control Contable',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.dashboard,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

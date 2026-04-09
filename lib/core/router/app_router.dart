import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/compras/compras_screen.dart';
import '../../screens/compras/crear_compra_screen.dart';
import '../../screens/ventas/ventas_screen.dart';
import '../../screens/ventas/crear_venta_screen.dart';
import '../../screens/importaciones/importaciones_screen.dart';
import '../../screens/importaciones/crear_importacion_screen.dart';
import '../../screens/importaciones/detalle_carpeta_screen.dart'; // <--- IMPORTANTE
import '../../screens/impositivo/impositivo_screen.dart';
import '../../screens/gastos/gastos_screen.dart';
import '../../screens/cobrar/cobrar_screen.dart';
import '../../screens/pagar/pagar_screen.dart';
import '../../screens/usuarios/usuarios_screen.dart';
import '../../screens/salidas/salidas_screen.dart';
import '../../screens/salidas/crear_salida_screen.dart';
import '../../screens/ingresos/ingresos_screen.dart';
import '../../screens/ingresos/crear_ingreso_screen.dart';
import '../../screens/reportes/reportes_screen.dart'; 

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String compras = '/compras';
  static const String crearCompra = '/compras/crear';
  static const String ventas = '/ventas';
  static const String crearVenta = '/ventas/crear';
  static const String importaciones = '/importaciones';
  static const String crearImportacion = '/importaciones/crear';
  static const String detalleImportacion = '/importaciones/detalle'; // <--- NUEVA RUTA
  static const String impositivo = '/impositivo';
  static const String gastos = '/gastos';
  static const String salidas = '/salidas';
  static const String crearSalida = '/salidas/crear';
  static const String ingresos = '/ingresos';
  static const String crearIngreso = '/ingresos/crear';
  static const String cobrar = '/cobrar';
  static const String pagar = '/pagar';
  static const String usuarios = '/usuarios';
  static const String reportes = '/reportes';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen(), settings: settings);
      case AppRoutes.compras:
        return MaterialPageRoute(builder: (_) => const ComprasScreen(), settings: settings);
      case AppRoutes.crearCompra:
        return MaterialPageRoute(builder: (_) => const CrearCompraScreen(), settings: settings);
      case AppRoutes.ventas:
        return MaterialPageRoute(builder: (_) => const VentasScreen(), settings: settings);
      case AppRoutes.crearVenta:
        return MaterialPageRoute(builder: (_) => const CrearVentaScreen(), settings: settings);
      case AppRoutes.reportes:
        return MaterialPageRoute(builder: (_) => const ReportesScreen()); // <--- EN LA SECCIÓN DEL SWITCH
      case AppRoutes.importaciones:
        return MaterialPageRoute(builder: (_) => const ImportacionesScreen(), settings: settings);
      case AppRoutes.crearImportacion:
        // Aquí pasamos el ID si es que venía como argumento (ahora abriremos la pantalla Detalles)
        final args = settings.arguments;
        final carpetaId = args is String ? args : null;
        
        if (carpetaId != null) {
          // Si hay ID, abrimos el Detalle
          return MaterialPageRoute(builder: (_) => DetalleCarpetaScreen(carpetaId: carpetaId), settings: settings);
        } else {
          // Si NO hay ID, abrimos el formulario de Creación
          return MaterialPageRoute(builder: (_) => const CrearImportacionScreen(), settings: settings);
        }

      case AppRoutes.impositivo:
        return MaterialPageRoute(builder: (_) => const ImpositivoScreen(), settings: settings);
      case AppRoutes.gastos:
        return MaterialPageRoute(builder: (_) => const GastosScreen(), settings: settings);
      case AppRoutes.cobrar:
        return MaterialPageRoute(builder: (_) => const CobrarScreen(), settings: settings);
      case AppRoutes.pagar:
        return MaterialPageRoute(builder: (_) => const PagarScreen(), settings: settings);
      case AppRoutes.salidas:
        return MaterialPageRoute(builder: (_) => const SalidasScreen(), settings: settings);
      case AppRoutes.crearSalida:
        return MaterialPageRoute(builder: (_) => const CrearSalidaScreen(), settings: settings);
      case AppRoutes.ingresos:
        return MaterialPageRoute(builder: (_) => const IngresosScreen(), settings: settings);
      case AppRoutes.crearIngreso:
        return MaterialPageRoute(builder: (_) => const CrearIngresoScreen(), settings: settings);
      case AppRoutes.usuarios:
        return MaterialPageRoute(builder: (_) => const UsuariosScreen(), settings: settings);
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}
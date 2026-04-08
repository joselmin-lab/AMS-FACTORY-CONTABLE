import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart'; // <--- Nueva pantalla de Login
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/compras/compras_screen.dart';
import '../../screens/compras/crear_compra_screen.dart';
import '../../screens/ventas/ventas_screen.dart';
import '../../screens/ventas/crear_venta_screen.dart';
import '../../screens/importaciones/importaciones_screen.dart';
import '../../screens/importaciones/crear_importacion_screen.dart';
import '../../screens/impositivo/impositivo_screen.dart';
import '../../screens/gastos/gastos_screen.dart';
import '../../screens/cobrar/cobrar_screen.dart';
import '../../screens/pagar/pagar_screen.dart';
import '../../screens/usuarios/usuarios_screen.dart';

class AppRoutes {
  static const String login = '/login'; // <--- Nueva ruta
  static const String dashboard = '/dashboard';
  static const String compras = '/compras';
  static const String crearCompra = '/compras/crear';
  static const String ventas = '/ventas';
  static const String crearVenta = '/ventas/crear';
  static const String importaciones = '/importaciones';
  static const String crearImportacion = '/importaciones/crear';
  static const String impositivo = '/impositivo';
  static const String gastos = '/gastos';
  
  // Nombres corregidos para que coincidan con el Drawer y Dashboard
  static const String cobrar = '/cobrar';
  static const String pagar = '/pagar';
  
  static const String usuarios = '/usuarios';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppRoutes.compras:
        return MaterialPageRoute(builder: (_) => const ComprasScreen());
      case AppRoutes.crearCompra:
        return MaterialPageRoute(builder: (_) => const CrearCompraScreen());
      case AppRoutes.ventas:
        return MaterialPageRoute(builder: (_) => const VentasScreen());
      case AppRoutes.crearVenta:
        return MaterialPageRoute(builder: (_) => const CrearVentaScreen());
      case AppRoutes.importaciones:
        return MaterialPageRoute(builder: (_) => const ImportacionesScreen());
      case AppRoutes.crearImportacion:
        return MaterialPageRoute(builder: (_) => const CrearImportacionScreen());
      case AppRoutes.impositivo:
        return MaterialPageRoute(builder: (_) => const ImpositivoScreen());
      case AppRoutes.gastos:
        return MaterialPageRoute(builder: (_) => const GastosScreen());
      case AppRoutes.cobrar:
        return MaterialPageRoute(builder: (_) => const CobrarScreen());
      case AppRoutes.pagar:
        return MaterialPageRoute(builder: (_) => const PagarScreen());
      case AppRoutes.usuarios:
        return MaterialPageRoute(builder: (_) => const UsuariosScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}
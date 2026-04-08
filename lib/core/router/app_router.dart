import 'package:flutter/material.dart';
import 'package:ams_control_contable/screens/dashboard/dashboard_screen.dart';
import 'package:ams_control_contable/screens/compras/compras_screen.dart';
import 'package:ams_control_contable/screens/compras/crear_compra_screen.dart';
import 'package:ams_control_contable/screens/ventas/ventas_screen.dart';
import 'package:ams_control_contable/screens/ventas/crear_venta_screen.dart';
import 'package:ams_control_contable/screens/importaciones/importaciones_screen.dart';
import 'package:ams_control_contable/screens/importaciones/crear_importacion_screen.dart';
import 'package:ams_control_contable/screens/impositivo/impositivo_screen.dart';
import 'package:ams_control_contable/screens/usuarios/usuarios_screen.dart';
import 'package:ams_control_contable/screens/gastos/gastos_screen.dart';
import 'package:ams_control_contable/screens/cobrar/cobrar_screen.dart';
import 'package:ams_control_contable/screens/pagar/pagar_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String compras = '/compras';
  static const String crearCompra = '/compras/crear';
  static const String ventas = '/ventas';
  static const String crearVenta = '/ventas/crear';
  static const String importaciones = '/importaciones';
  static const String crearImportacion = '/importaciones/crear';
  static const String impositivo = '/impositivo';
  static const String usuarios = '/usuarios';
  static const String gastos = '/gastos';
  static const String cobrar = '/cobrar';
  static const String pagar = '/pagar';
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case AppRoutes.compras:
        return MaterialPageRoute(
          builder: (_) => const ComprasScreen(),
          settings: settings,
        );
      case AppRoutes.crearCompra:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CrearCompraScreen(compraId: args?['id']),
          settings: settings,
        );
      case AppRoutes.ventas:
        return MaterialPageRoute(
          builder: (_) => const VentasScreen(),
          settings: settings,
        );
      case AppRoutes.crearVenta:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CrearVentaScreen(ventaId: args?['id']),
          settings: settings,
        );
      case AppRoutes.importaciones:
        return MaterialPageRoute(
          builder: (_) => const ImportacionesScreen(),
          settings: settings,
        );
      case AppRoutes.crearImportacion:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) =>
              CrearImportacionScreen(importacionId: args?['id']),
          settings: settings,
        );
      case AppRoutes.impositivo:
        return MaterialPageRoute(
          builder: (_) => const ImpositivoScreen(),
          settings: settings,
        );
      case AppRoutes.usuarios:
        return MaterialPageRoute(
          builder: (_) => const UsuariosScreen(),
          settings: settings,
        );
      case AppRoutes.gastos:
        return MaterialPageRoute(
          builder: (_) => const GastosScreen(),
          settings: settings,
        );
      case AppRoutes.cobrar:
        return MaterialPageRoute(
          builder: (_) => const CobrarScreen(),
          settings: settings,
        );
      case AppRoutes.pagar:
        return MaterialPageRoute(
          builder: (_) => const PagarScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
    }
  }
}

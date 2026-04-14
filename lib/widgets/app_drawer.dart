import 'package:flutter/material.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentRoute =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  label: AppStrings.dashboard,
                  route: AppRoutes.dashboard,
                  currentRoute: currentRoute,
                  color: AppColors.primary,
                ),
                const Divider(height: 1),
                _buildSectionHeader('Movimientos'),
                _buildNavItem(
                  context: context,
                  icon: Icons.shopping_cart_rounded,
                  label: AppStrings.compras,
                  route: AppRoutes.compras,
                  currentRoute: currentRoute,
                  color: AppColors.comprasColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.point_of_sale_rounded,
                  label: AppStrings.ventas,
                  route: AppRoutes.ventas,
                  currentRoute: currentRoute,
                  color: AppColors.ventasColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.local_shipping_rounded,
                  label: AppStrings.importaciones,
                  route: AppRoutes.importaciones,
                  currentRoute: currentRoute,
                  color: AppColors.importacionesColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.analytics_outlined,
                  label: 'Reportes Generales',
                  route: AppRoutes.reportes,
                  currentRoute: currentRoute,
                  color: Colors.amber, 
                ),
                const Divider(height: 1),
                _buildSectionHeader('Finanzas'),
                _buildNavItem(
                  context: context,
                  icon: Icons.account_balance_rounded,
                  label: AppStrings.impositivo,
                  route: AppRoutes.impositivo,
                  currentRoute: currentRoute,
                  color: AppColors.impositivoColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.money_off_rounded,
                  label: AppStrings.gastos,
                  route: AppRoutes.gastos,
                  currentRoute: currentRoute,
                  color: AppColors.gastosColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.receipt_long_rounded,
                  label: 'Salidas Extra',
                  route: '/salidas', // AppRoutes.salidas
                  currentRoute: currentRoute,
                  color: Colors.deepOrange,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.savings_rounded,
                  label: 'Ingresos Extra',
                  route: AppRoutes.ingresos, 
                  currentRoute: currentRoute,
                  color: Colors.teal,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.arrow_circle_down_rounded,
                  label: AppStrings.cuentasPorCobrar,
                  route: AppRoutes.cobrar,
                  currentRoute: currentRoute,
                  color: AppColors.cobrarColor,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.arrow_circle_up_rounded,
                  label: AppStrings.cuentasPorPagar,
                  route: AppRoutes.pagar,
                  currentRoute: currentRoute,
                  color: AppColors.pagarColor,
                ),
                const Divider(height: 1),
                _buildSectionHeader('Administración'),
                _buildNavItem(
                  context: context,
                  icon: Icons.people_rounded,
                  label: AppStrings.usuarios,
                  route: AppRoutes.usuarios,
                  currentRoute: currentRoute,
                  color: AppColors.usuariosColor,
                ),
                _buildNavItem(
                  context: context, 
                  icon: Icons.group, 
                  label: 'Clientes', 
                  route: AppRoutes.clientes, 
                  currentRoute: currentRoute, 
                  color: Colors.teal
                ),
                
                // --- BOTON CERRAR SESION PEGADO DEBAJO DE CLIENTES ---
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.black12),
                Container(
                  color: const Color(0xFF1E293B), // Fondo oscuro para que resalte
                  child: ListTile(
                    leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Cerrar Sesión?'),
                          content: const Text('¿Estás seguro que deseas salir de tu cuenta?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true), 
                              child: const Text('Salir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true && context.mounted) {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 40), // Espacio extra al final del scroll
              ],
            ),
          ),
        ],
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.appName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            AppStrings.appSubtitle,
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

    Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required String currentRoute,
    required Color color,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isSelected ? color : Colors.grey.shade600),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: color.withAlpha(26),
      onTap: () {
        Navigator.pop(context); // Cierra el menú lateral (Drawer) siempre
        
        if (!isSelected) {
          if (route == AppRoutes.dashboard) {
            // Si vamos al Dashboard, borramos todo el historial de pantallas y volvemos a la raíz
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
          } else {
            // Si vamos a cualquier otra pantalla, la reemplazamos
            Navigator.pushReplacementNamed(context, route);
          }
        }
      },
    );
  }

  
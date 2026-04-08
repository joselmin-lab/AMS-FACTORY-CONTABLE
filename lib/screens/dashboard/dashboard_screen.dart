import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/services/compras_service.dart';
import 'package:ams_control_contable/services/ventas_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: AppStrings.appLocale, symbol: AppStrings.currencySymbol, decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComprasService>().fetchCompras();
      context.read<VentasService>().fetchVentas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<ComprasService>().fetchCompras();
              context.read<VentasService>().fetchVentas();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ComprasService>().fetchCompras();
          await context.read<VentasService>().fetchVentas();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(context),
              const SizedBox(height: 20),
              _buildSectionTitle('Resumen General'),
              const SizedBox(height: 12),
              _buildSummaryGrid(context),
              const SizedBox(height: 20),
              _buildSectionTitle('Accesos Rápidos'),
              const SizedBox(height: 12),
              _buildQuickAccess(context),
              const SizedBox(height: 20),
              _buildSectionTitle('Módulos'),
              const SizedBox(height: 12),
              _buildModuleGrid(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM y', AppStrings.appLocale).format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white30,
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    final comprasService = context.watch<ComprasService>();
    final ventasService = context.watch<VentasService>();

    final totalVentas = ventasService.totalVentas;
    final totalCompras = comprasService.totalCompras;
    final utilidad = totalVentas - totalCompras;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        SummaryCard(
          title: AppStrings.ingresos,
          value: _currencyFormat.format(totalVentas),
          icon: Icons.trending_up_rounded,
          color: AppColors.ventasColor,
          subtitle: '${ventasService.ventas.length} ventas',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.ventas),
        ),
        SummaryCard(
          title: AppStrings.egresos,
          value: _currencyFormat.format(totalCompras),
          icon: Icons.trending_down_rounded,
          color: AppColors.comprasColor,
          subtitle: '${comprasService.compras.length} compras',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.compras),
        ),
        SummaryCard(
          title: AppStrings.utilidadNeta,
          value: _currencyFormat.format(utilidad),
          icon: Icons.analytics_rounded,
          color: utilidad >= 0 ? AppColors.success : AppColors.error,
          subtitle: utilidad >= 0 ? 'Positivo' : 'Negativo',
        ),
        SummaryCard(
          title: AppStrings.saldoCaja,
          value: _currencyFormat.format(utilidad),
          icon: Icons.account_balance_rounded,
          color: AppColors.accent,
          subtitle: 'Estimado',
        ),
      ],
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessButton(
            label: 'Nueva Compra',
            icon: Icons.add_shopping_cart_rounded,
            color: AppColors.comprasColor,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.crearCompra),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessButton(
            label: 'Nueva Venta',
            icon: Icons.add_box_rounded,
            color: AppColors.ventasColor,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.crearVenta),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessButton(
            label: 'Importación',
            icon: Icons.flight_land_rounded,
            color: AppColors.importacionesColor,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.crearImportacion),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _ModuleItem(AppStrings.compras, Icons.shopping_cart_rounded,
          AppColors.comprasColor, AppRoutes.compras),
      _ModuleItem(AppStrings.ventas, Icons.point_of_sale_rounded,
          AppColors.ventasColor, AppRoutes.ventas),
      _ModuleItem(AppStrings.importaciones, Icons.local_shipping_rounded,
          AppColors.importacionesColor, AppRoutes.importaciones),
      _ModuleItem(AppStrings.impositivo, Icons.account_balance_rounded,
          AppColors.impositivoColor, AppRoutes.impositivo),
      _ModuleItem(AppStrings.gastos, Icons.money_off_rounded,
          AppColors.gastosColor, AppRoutes.gastos),
      _ModuleItem(AppStrings.cuentasPorCobrar, Icons.arrow_circle_down_rounded,
          AppColors.cobrarColor, AppRoutes.cobrar),
      _ModuleItem(AppStrings.cuentasPorPagar, Icons.arrow_circle_up_rounded,
          AppColors.pagarColor, AppRoutes.pagar),
      _ModuleItem(AppStrings.usuarios, Icons.people_rounded,
          AppColors.usuariosColor, AppRoutes.usuarios),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _ModuleGridItem(
          label: module.label,
          icon: module.icon,
          color: module.color,
          onTap: () => Navigator.pushNamed(context, module.route),
        );
      },
    );
  }
}

class _ModuleItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  _ModuleItem(this.label, this.icon, this.color, this.route);
}

class _QuickAccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGridItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleGridItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

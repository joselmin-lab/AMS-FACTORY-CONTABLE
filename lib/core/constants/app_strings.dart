class AppStrings {
  AppStrings._();

  static const String appLocale = 'es';
  static const String currencySymbol = 'Bs.';
  static const String appName = 'AMS Control Contable';
  static const String appSubtitle = 'Fábrica de Amortiguadores';

  // Navigation
  static const String dashboard = 'Dashboard';
  static const String compras = 'Compras';
  static const String ventas = 'Ventas';
  static const String importaciones = 'Importaciones';
  static const String impositivo = 'Módulo Impositivo';
  static const String usuarios = 'Usuarios';
  static const String gastos = 'Gastos';
  static const String cuentasPorCobrar = 'Cuentas por Cobrar';
  static const String cuentasPorPagar = 'Cuentas por Pagar';

  // Actions
  static const String crear = 'Crear';
  static const String editar = 'Editar';
  static const String eliminar = 'Eliminar';
  static const String guardar = 'Guardar';
  static const String cancelar = 'Cancelar';
  static const String confirmar = 'Confirmar';
  static const String buscar = 'Buscar';

  // Form labels
  static const String cantidad = 'Cantidad';
  static const String precio = 'Precio';
  static const String facturado = '¿Facturado?';
  static const String proveedor = 'Proveedor';
  static const String cliente = 'Cliente';
  static const String metodoPago = 'Método de Pago';
  static const String descripcion = 'Descripción';
  static const String fecha = 'Fecha';
  static const String total = 'Total';
  static const String subtotal = 'Subtotal';
  static const String notas = 'Notas';

  // Metodos de pago
  static const String pagoQR = 'QR';
  static const String pagoEfectivo = 'Efectivo';
  static const String pagoTarjeta = 'Tarjeta';
  static const String pagoCredito = 'Crédito';

  // Importaciones
  static const String precioUsFabrica = 'Precio US\$ Fábrica/Proveedor';
  static const String porcentajeGA = '% GA';
  static const String porcentajeIVA = '% IVA';
  static const String tipoCambio = 'Tipo de Cambio US\$';
  static const String costoFlete = 'Costo Flete';
  static const String costoDespachante = 'Costo Despachante de Aduanas';
  static const String otrosCostos = 'Otros Costos';
  static const String costoTotal = 'Costo Total (calculado)';

  // Impositivo
  static const String ivaVentas = '% IVA en Ventas';
  static const String itVentas = '% IT en Ventas';
  static const String ivaCompras = '% IVA en Compras';
  static const String iueUtilidades = '% IUE en Utilidades';

  // Dashboard
  static const String ingresos = 'Ingresos';
  static const String egresos = 'Egresos';
  static const String saldoCaja = 'Saldo en Caja';
  static const String utilidadNeta = 'Utilidad Neta';
  static const String totalCobrar = 'Total por Cobrar';
  static const String totalPagar = 'Total por Pagar';

  // Messages
  static const String noHayDatos = 'No hay datos disponibles';
  static const String cargando = 'Cargando...';
  static const String errorCarga = 'Error al cargar los datos';
  static const String confirmEliminar =
      '¿Está seguro de que desea eliminar este registro?';
  static const String registroGuardado = 'Registro guardado correctamente';
  static const String registroEliminado = 'Registro eliminado correctamente';
  static const String monto = 'Monto';
  static const String campoRequerido = 'Este campo es requerido';
  static const String valorInvalido = 'Por favor ingrese un valor válido';
}

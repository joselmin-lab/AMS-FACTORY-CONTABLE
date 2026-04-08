# AMS Control Contable

Sistema de control contable para la Fábrica de Amortiguadores AMS.

## 📋 Descripción

Aplicación Flutter para la gestión contable de la fábrica, diseñada para integrarse con el mismo backend Supabase del proyecto hermano **AMS-FACTORY-MIMS**.

## 🧩 Módulos

| Módulo | Descripción |
|--------|-------------|
| **Dashboard** | Resumen de ingresos, egresos y utilidad neta |
| **Compras** | Registro y gestión de movimientos de compra |
| **Ventas** | Registro y gestión de movimientos de venta |
| **Importaciones** | Cálculo de costos de importación (GA, IVA, flete, despachante) |
| **Módulo Impositivo** | Configuración de % IVA, IT, IUE |
| **Gastos** | Gastos fijos, variables y sueldos |
| **Cuentas por Cobrar** | Control de deudas de clientes |
| **Cuentas por Pagar** | Control de deudas a proveedores |
| **Usuarios** | Gestión de perfiles y roles |

## 🛠 Tecnologías

- **Flutter** (Material Design 3)
- **Provider** para estado
- **Supabase** como backend
- **intl** para formateo de fechas y monedas

## 🚀 Instalación

### 1. Prerrequisitos

- Flutter SDK ≥ 3.0.0
- Cuenta en [Supabase](https://supabase.com)

### 2. Clonar y configurar dependencias

```bash
git clone https://github.com/joselmin-lab/AMS-FACTORY-CONTABLE.git
cd AMS-FACTORY-CONTABLE
flutter pub get
```

### 3. Configurar Supabase

Edita `lib/main.dart` y reemplaza:

```dart
const String _supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const String _supabaseAnonKey = 'YOUR_ANON_KEY';
```

Luego descomenta la inicialización de Supabase en `main()`:

```dart
await SupabaseService.initialize(
  supabaseUrl: _supabaseUrl,
  supabaseAnonKey: _supabaseAnonKey,
);
```

### 4. Tablas requeridas en Supabase

```sql
-- Compras
CREATE TABLE compras_contable (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  parte_id uuid,
  parte_nombre text,
  cantidad numeric NOT NULL,
  precio numeric NOT NULL,
  facturado boolean DEFAULT false,
  proveedor text NOT NULL,
  metodo_pago text NOT NULL,
  fecha timestamptz DEFAULT now(),
  notas text,
  usuario_id uuid
);

-- Ventas
CREATE TABLE ventas_contable (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  parte_id uuid,
  parte_nombre text,
  cantidad numeric NOT NULL,
  precio numeric NOT NULL,
  facturado boolean DEFAULT false,
  cliente text NOT NULL,
  metodo_pago text NOT NULL,
  fecha timestamptz DEFAULT now(),
  notas text,
  usuario_id uuid
);

-- Importaciones
CREATE TABLE importaciones (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  items jsonb NOT NULL DEFAULT '[]',
  porcentaje_ga numeric DEFAULT 0,
  porcentaje_iva numeric DEFAULT 13,
  tipo_cambio numeric DEFAULT 6.96,
  costo_flete numeric DEFAULT 0,
  costo_despachante numeric DEFAULT 0,
  otros_costos numeric DEFAULT 0,
  costo_total numeric,
  fecha timestamptz DEFAULT now(),
  notas text,
  usuario_id uuid
);
```

### 5. Ejecutar la app

```bash
flutter run
```

## 📁 Estructura del proyecto

```
lib/
├── core/
│   ├── constants/     # Colores, strings
│   ├── router/        # Enrutamiento
│   └── theme/         # Tema Material
├── models/            # Modelos de datos
├── screens/           # Pantallas por módulo
│   ├── dashboard/
│   ├── compras/
│   ├── ventas/
│   ├── importaciones/
│   ├── impositivo/
│   ├── gastos/
│   ├── cobrar/
│   ├── pagar/
│   └── usuarios/
├── services/          # Lógica de negocio / Supabase
├── widgets/           # Componentes reutilizables
└── main.dart
```

## 🧪 Tests

```bash
flutter test
```

## 🔗 Proyecto hermano

Este proyecto se integra con **AMS-FACTORY-MIMS** para acceder al inventario compartido (partes, insumos, productos finales).

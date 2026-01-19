# Resumen de Vistas - Portal Web Frontend

## 📋 Índice de Pantallas

### Total de Pantallas: **23 vistas**

---

## 🔐 **AUTENTICACIÓN Y CONFIGURACIÓN** (4 pantallas)

### 1. **Splash Screen** (`splash_screen.dart`)
- **Tipo**: StatelessWidget
- **Función**: Pantalla de carga inicial
- **Funcionalidad**:
  - Verifica token existente
  - Redirección automática según estado de autenticación
  - Pantalla de bienvenida

### 2. **Login Screen** (`login_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Autenticación de usuarios
- **Funcionalidad**:
  - Formulario de login (usuario/clave)
  - Validación de campos
  - Manejo de errores
  - Redirección al dashboard tras login exitoso
  - Almacenamiento de token JWT

### 3. **Cambiar Clave Screen** (`cambiar_clave_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Cambio de contraseña
- **Funcionalidad**:
  - Formulario de cambio de contraseña
  - Validación de contraseña actual
  - Confirmación de nueva contraseña
  - Validaciones de seguridad
  - Actualización en backend

### 4. **Cambiar Sucursal Screen** (`cambiar_sucursal_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Selección de sucursal activa
- **Funcionalidad**:
  - Listado de sucursales disponibles del usuario
  - Selección de sucursal activa
  - Confirmación de cambio
  - Actualización automática de datos

---

## 🏠 **DASHBOARD Y NAVEGACIÓN** (1 pantalla)

### 5. **Home Screen** (`home_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Dashboard principal
- **Funcionalidad**:
  - **Módulos principales**:
    - Estimaciones
    - Pautas
    - Mapeo
    - Conteo
    - Parámetros
    - Producción
    - Riego
    - Actividades
  - Búsqueda en menú
  - Acciones rápidas
  - Información del usuario
  - Selector de sucursal
  - Cambio de tema
  - Cerrar sesión
  - Navegación a todas las pantallas

---

## 📊 **ESTIMACIONES Y REPORTES** (2 pantallas)

### 6. **Estimaciones Screen** (`estimaciones_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Dashboard de estimaciones de producción
- **Funcionalidad**:
  - **Vista General**:
    - Especies agrupadas
    - Totales generales
    - Tipos de estimación
  - **Filtros**:
    - Por especie
    - Por variedad
    - Por temporada
    - Búsqueda
  - **Vista Detallada**:
    - Información completa de cuartel
    - Estimaciones históricas
    - Pautas asociadas
    - Rendimientos packing
    - Mapeos
    - Frutos por ramilla
    - Calibres
  - **Gráficos**: Visualización de datos
  - **Exportación**: Exportar a Excel
  - **Modales**:
    - Crear nueva pauta
    - Crear rendimiento packing

### 7. **Historial Cuartel Screen** (`historial_cuartel_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Historial detallado de un cuartel
- **Funcionalidad**:
  - Historial completo de actividades
  - Registros de estimaciones
  - Pautas aplicadas
  - Mapeos realizados
  - Filtros por fecha

---

## 📝 **PAUTAS DE TRABAJO** (5 pantallas)

### 8. **Pautas Gestión Screen** (`pautas_gestion_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Gestión general de pautas
- **Funcionalidad**:
  - Listado de pautas
  - Filtros por temporada
  - Búsqueda de pautas
  - Vista de detalle de pauta
  - Navegación a crear/editar pauta

### 9. **Pautas Crear Nueva Screen** (`pautas_crear_nueva_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Creación de nueva pauta
- **Funcionalidad**:
  - Formulario de creación
  - Selección de configuración
  - Parámetros de pauta
  - Validación de datos
  - Envío a backend

### 10. **Pautas Formulario Screen** (`pautas_formulario_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Formulario estándar de pautas
- **Funcionalidad**:
  - Formulario con campos fijos
  - Validación de campos
  - Guardado de pauta

### 11. **Pautas Formulario Dinámico Screen** (`pautas_formulario_dinamico_screen.dart`)
- **Tipo**: StatefulWidget (con SingleTickerProviderStateMixin)
- **Función**: Formulario dinámico según tipo de conteo
- **Funcionalidad**:
  - Formulario que se adapta al tipo de conteo
  - Campos dinámicos según configuración
  - Validación adaptativa
  - Tabs para organización

### 12. **Pautas Configuración Screen** (`pautas_configuracion_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Configuración de pautas
- **Funcionalidad**:
  - Gestión de configuraciones de pauta
  - Asociaciones labor-especie
  - Atributos disponibles
  - Tipos de planta
  - CRUD de configuraciones

---

## 🗺️ **MAPEO AGRÍCOLA** (1 pantalla)

### 13. **Mapeo Screen** (`mapeo_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Administración completa de mapeo
- **Funcionalidad**:
  - **Gestión de Cuarteles**:
    - Listado de cuarteles
    - Selección múltiple
    - Filtros
  - **Carga Masiva**:
    - Carga de archivo Excel
    - Importación de cuarteles, hileras y plantas
    - Validación de datos
    - Procesamiento masivo
  - **Hileras**:
    - Visualización de hileras por cuartel
    - Tarjetas expandibles
    - Información detallada
  - **Plantas**:
    - Visualización de plantas por hilera
    - Exportación a Excel
    - Información completa
  - **Catastro**:
    - Proceso de catastro completo
    - Validación de estructura
    - Actualización masiva

---

## 🔢 **CONTEO DE PLANTAS** (3 pantallas)

### 14. **Conteo Atributo Especie Screen** (`conteo_atributo_especie_screen.dart`)
- **Tipo**: StatefulWidget (con SingleTickerProviderStateMixin)
- **Función**: Conteo por atributo y especie
- **Funcionalidad**:
  - Selección de atributo
  - Selección de especie
  - Visualización de conteos
  - Filtros y búsqueda
  - Tabs para organización

### 15. **Conteo Atributo Optimo Screen** (`conteo_atributo_optimo_screen.dart`)
- **Tipo**: StatefulWidget (con SingleTickerProviderStateMixin)
- **Función**: Gestión de atributos óptimos
- **Funcionalidad**:
  - Listado de atributos óptimos
  - Configuración de valores óptimos
  - Edad mínima/máxima
  - Valores por hectárea
  - CRUD de atributos óptimos
  - Tabs para organización

### 16. **Manejo Parámetros Conteo Screen** (`manejo_parametros_conteo_screen.dart`)
- **Tipo**: StatefulWidget (con SingleTickerProviderStateMixin)
- **Función**: Configuración de parámetros de conteo
- **Funcionalidad**:
  - Gestión de parámetros de conteo
  - Reglas de conteo
  - Valores óptimos
  - Configuración de reglas
  - Tabs para organización

---

## 👥 **ADMINISTRACIÓN DE USUARIOS** (1 pantalla)

### 17. **Admin Usuarios Screen** (`admin_usuarios_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Gestión completa de usuarios
- **Funcionalidad**:
  - **CRUD Completo**:
    - Listar usuarios (tabla con paginación)
    - Crear usuario
    - Editar usuario
    - Desactivar usuario
  - **Búsqueda y Filtros**:
    - Búsqueda por texto
    - Filtro por perfil
    - Filtro por sucursal
    - Filtro por estado
    - Ordenamiento por columnas
  - **Gestión de Permisos**:
    - Asignar permisos a usuarios
    - Listado de permisos disponibles
    - Permisos por aplicación
  - **Gestión de Accesos**:
    - Asignar sucursales permitidas
    - Asignar aplicaciones permitidas
    - Gestión de perfiles
  - **Formularios**:
    - Formulario de creación/edición
    - Validación de campos
    - Selección múltiple de permisos/apps/sucursales
  - **Tabla Avanzada**:
    - Paginación (20 usuarios por página)
    - Ordenamiento
    - Acciones por fila
    - Información detallada

---

## ⚙️ **PARÁMETROS Y CONFIGURACIÓN** (2 pantallas)

### 18. **Parámetros Screen** (`parametros_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Administración central de parámetros
- **Funcionalidad**:
  - **Categorías de Parámetros**:
    - Mapeo
    - Administración de Usuarios
    - Conteo Atributo Óptimo
    - Conteo Atributo Especie
    - Estimaciones
    - Pautas Configuración
    - Pautas Formulario
    - Pautas Gestión
    - Manejo Parámetros Conteo
    - Muestras
    - Configuración Asociaciones
    - Pautas Formulario Dinámico
  - **Navegación**: Acceso rápido a todas las pantallas de configuración
  - **Grid de Categorías**: Tarjetas organizadas por categoría

### 19. **Configuración Asociaciones Screen** (`configuracion_asociaciones_screen.dart`)
- **Tipo**: StatefulWidget (con SingleTickerProviderStateMixin)
- **Función**: Configuración de asociaciones
- **Funcionalidad**:
  - Gestión de asociaciones labor-especie
  - Configuración de relaciones
  - Tabs para organización

---

## 📈 **REPORTES Y ANÁLISIS** (1 pantalla)

### 20. **Muestras Screen** (`muestras_screen.dart`)
- **Tipo**: StatefulWidget (con SingleTickerProviderStateMixin)
- **Función**: Gestión de muestras
- **Funcionalidad**:
  - Gestión de muestras agrícolas
  - Registro de muestras
  - Análisis de muestras
  - Tabs para organización

---

## 🚧 **EN DESARROLLO** (3 pantallas)

### 21. **Producción Screen** (`produccion_screen.dart`)
- **Tipo**: StatelessWidget
- **Estado**: ⚠️ **En desarrollo**
- **Función**: Reportes de producción
- **Funcionalidad Actual**:
  - Placeholder con mensaje "Funcionalidad en desarrollo"
  - Estructura básica lista

### 22. **Riego Screen** (`riego_screen.dart`)
- **Tipo**: StatelessWidget
- **Estado**: ⚠️ **En desarrollo**
- **Función**: Gestión de riego
- **Funcionalidad Actual**:
  - Placeholder con mensaje "Funcionalidad en desarrollo"
  - Estructura básica lista

### 23. **Actividades Screen** (`actividades_screen.dart`)
- **Tipo**: StatelessWidget
- **Estado**: ⚠️ **En desarrollo**
- **Función**: Gestión de actividades
- **Funcionalidad Actual**:
  - Placeholder con mensaje "Funcionalidad en desarrollo"
  - Estructura básica lista

---

## 🧪 **TESTING Y DESARROLLO** (1 pantalla)

### 24. **Looker Test Screen** (`looker_test_screen.dart`)
- **Tipo**: StatefulWidget
- **Función**: Pruebas de integración con Looker
- **Funcionalidad**:
  - Testing de conexión con Looker
  - Pruebas de visualizaciones
  - Debug de integraciones

---

## 📊 **Resumen por Categoría**

| Categoría | Cantidad | Estado |
|-----------|----------|--------|
| Autenticación | 4 | ✅ Completo |
| Dashboard | 1 | ✅ Completo |
| Estimaciones | 2 | ✅ Completo |
| Pautas | 5 | ✅ Completo |
| Mapeo | 1 | ✅ Completo |
| Conteo | 3 | ✅ Completo |
| Administración | 1 | ✅ Completo |
| Parámetros | 2 | ✅ Completo |
| Reportes | 1 | ✅ Completo |
| En Desarrollo | 3 | ⚠️ Pendiente |
| Testing | 1 | ✅ Completo |
| **TOTAL** | **24** | **20 completas / 3 en desarrollo / 1 testing** |

---

## 🎯 **Funcionalidades Principales por Pantalla**

### Pantallas Más Complejas:

1. **Admin Usuarios Screen**: ~2900 líneas
   - CRUD completo
   - Tabla avanzada con paginación
   - Gestión de permisos y accesos
   - Múltiples formularios

2. **Estimaciones Screen**: ~3000+ líneas
   - Dashboard completo
   - Múltiples vistas
   - Gráficos y visualizaciones
   - Exportación a Excel
   - Modales complejos

3. **Mapeo Screen**: ~3100+ líneas
   - Gestión completa de mapeo
   - Carga masiva de archivos
   - Procesamiento de Excel
   - Múltiples funcionalidades

4. **Parámetros Screen**: ~1000+ líneas
   - Hub central de configuración
   - Navegación a múltiples pantallas
   - Grid de categorías

---

## 🔗 **Navegación y Flujo**

### Flujo Principal:
```
Splash → Login → Home (Dashboard)
                ↓
    ┌───────────┼───────────┐
    │           │           │
Estimaciones  Pautas     Mapeo
    │           │           │
    └───────────┼───────────┘
                ↓
         Parámetros
                ↓
    ┌───────────┼───────────┐
    │           │           │
  Conteo    Admin Usuarios  Otros
```

### Acceso desde Home:
- Todos los módulos principales accesibles desde el dashboard
- Navegación mediante menú lateral
- Búsqueda rápida de módulos

---

## 📝 **Notas Técnicas**

### Widgets Reutilizables:
- `MainScaffold`: Scaffold principal con AppBar y Sidebar
- `SucursalSelector`: Selector de sucursal activa
- `PersistentSidebar`: Sidebar con navegación

### Patrones Utilizados:
- **StatefulWidget**: Para pantallas con estado
- **Provider**: Para gestión de estado global
- **SingleTickerProviderStateMixin**: Para animaciones/tabs
- **Formularios**: Validación y manejo de datos
- **Tablas**: DataTable2 para tablas avanzadas
- **Modales**: Diálogos y bottom sheets

### Integraciones:
- **HTTP**: Comunicación con API
- **Excel**: Exportación/importación de datos
- **Gráficos**: fl_chart para visualizaciones
- **Navegación**: Sistema de rutas personalizado

---

## ✅ **Estado General del Frontend**

### Completitud: **83%** (20/24 pantallas completas)

### Fortalezas:
- ✅ Arquitectura clara y modular
- ✅ Navegación bien estructurada
- ✅ Pantallas complejas bien implementadas
- ✅ Reutilización de componentes
- ✅ Manejo de estado consistente
- ✅ Integración completa con API

### Áreas de Mejora:
- ⚠️ Completar 3 pantallas en desarrollo
- ⚠️ Agregar más tests unitarios
- ⚠️ Optimizar rendimiento en pantallas grandes
- ⚠️ Mejorar manejo de errores en algunas pantallas

---

**Última actualización**: Diciembre 2024  
**Versión**: 1.0.0


# Documentación Frontend - Portal Web Frontend

## 📋 Índice

1. [Descripción General](#descripción-general)
2. [Arquitectura](#arquitectura)
3. [Tecnologías](#tecnologías)
4. [Configuración](#configuración)
5. [Estructura del Proyecto](#estructura-del-proyecto)
6. [Pantallas y Funcionalidades](#pantallas-y-funcionalidades)
7. [Servicios](#servicios)
8. [Providers (Estado Global)](#providers-estado-global)
9. [Temas y UI](#temas-y-ui)
10. [Desarrollo](#desarrollo)
11. [Despliegue](#despliegue)

---

## 📖 Descripción General

Portal Web Frontend es una aplicación web desarrollada en Flutter que proporciona una interfaz de usuario para gestionar información agrícola. Permite visualizar reportes, gestionar parámetros para aplicaciones móviles, administrar usuarios, roles y permisos.

### Funcionalidades Principales

- **Autenticación**: Login con JWT, gestión de sesión
- **Dashboard**: Vista principal con módulos y estadísticas
- **Gestión de Cuarteles**: Visualización y gestión de cuarteles
- **Estimaciones**: Dashboard de estimaciones de producción
- **Pautas de Trabajo**: Configuración y gestión de pautas
- **Mapeo**: Visualización de mapeos agrícolas
- **Conteo**: Gestión de conteos de plantas
- **Parámetros**: Configuración de parámetros del sistema
- **Administración de Usuarios**: CRUD de usuarios, roles y permisos
- **Producción**: Reportes de producción
- **Riego**: Gestión de riego (en desarrollo)
- **Actividades**: Gestión de actividades (en desarrollo)

---

## 🏗️ Arquitectura

La aplicación sigue una arquitectura basada en **Provider** para gestión de estado y una estructura modular clara.

### Patrón de Diseño

- **Provider Pattern**: Gestión de estado global
- **Service Pattern**: Servicios para comunicación con API
- **Widget Pattern**: Componentes reutilizables
- **Screen Pattern**: Pantallas organizadas por funcionalidad

### Componentes Principales

```
PORTAL_WEB_FRONTEND/
├── lib/
│   ├── main.dart                    # Punto de entrada
│   ├── firebase_options.dart        # Configuración Firebase
│   └── src/
│       ├── app.dart                 # Configuración de la app
│       ├── config/
│       │   └── api_config.dart      # Configuración de API
│       ├── providers/               # Providers de estado
│       │   ├── auth_provider.dart   # Estado de autenticación
│       │   ├── theme_provider.dart  # Estado de tema
│       │   └── sidebar_provider.dart # Estado de sidebar
│       ├── screens/                 # Pantallas
│       │   ├── splash_screen.dart
│       │   ├── login_screen.dart
│       │   ├── home_screen.dart
│       │   ├── estimaciones_screen.dart
│       │   ├── pautas_*.dart
│       │   ├── mapeo_screen.dart
│       │   ├── admin_usuarios_screen.dart
│       │   └── ...
│       ├── services/                # Servicios
│       │   ├── auth_service.dart    # Servicio de autenticación
│       │   ├── http_interceptor.dart # Interceptor HTTP
│       │   └── navigation_service.dart # Servicio de navegación
│       ├── theme/
│       │   └── app_theme.dart        # Configuración de temas
│       └── widgets/                 # Widgets reutilizables
│           ├── main_scaffold.dart    # Scaffold principal
│           ├── persistent_sidebar.dart # Sidebar persistente
│           └── sucursal_selector.dart # Selector de sucursal
├── assets/                          # Recursos estáticos
├── web/                             # Archivos web
└── pubspec.yaml                     # Dependencias
```

---

## 🛠️ Tecnologías

### Framework y Librerías Principales

- **Flutter 3.0+**: Framework de desarrollo multiplataforma
- **Provider 6.0.5**: Gestión de estado
- **HTTP 1.1.0**: Cliente HTTP para peticiones a la API
- **flutter_secure_storage 9.0.0**: Almacenamiento seguro de tokens
- **shared_preferences 2.2.0**: Almacenamiento local
- **flutter_dotenv 5.1.0**: Variables de entorno
- **intl 0.19.0**: Internacionalización y formato de fechas
- **fl_chart 0.65.0**: Gráficos y visualizaciones
- **data_table_2 2.5.10**: Tablas de datos avanzadas
- **excel 2.1.0**: Exportación a Excel

### Plataforma

- **Web**: Aplicación web responsive
- **Firebase Hosting**: Despliegue en Firebase

---

## ⚙️ Configuración

### Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:

```env
API_BASE_URL=https://api-portalweb-927498545444.us-central1.run.app/api
```

### Configuración de API

El archivo `lib/src/config/api_config.dart` centraliza la configuración de endpoints:

```dart
class ApiConfig {
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 
           'https://api-portalweb-927498545444.us-central1.run.app/api';
  }
  
  static String get authUrl => '$baseUrl/auth';
  static String get usuariosUrl => '$baseUrl/usuarios';
  static String get cuartelesUrl => '$baseUrl/cuarteles';
  // ...
}
```

---

## 📁 Estructura del Proyecto

### Providers (Gestión de Estado)

#### 1. **AuthProvider**
Gestiona el estado de autenticación:
- Token JWT
- Información del usuario
- Estado de sesión
- Métodos de login/logout

#### 2. **ThemeProvider**
Gestiona el tema de la aplicación:
- Tema claro/oscuro
- Cambio dinámico de tema
- Persistencia de preferencias

#### 3. **SidebarProvider**
Gestiona el estado del sidebar:
- Estado abierto/cerrado
- Persistencia de preferencias

### Servicios

#### 1. **AuthService**
Servicio de autenticación:
- Login
- Refresh token
- Cambio de contraseña
- Cambio de sucursal

#### 2. **HttpInterceptor**
Interceptor HTTP para:
- Agregar token JWT a peticiones
- Manejo de errores
- Refresh automático de token

#### 3. **NavigationService**
Servicio de navegación:
- Navegación entre pantallas
- Gestión de rutas
- Historial de navegación

### Widgets Reutilizables

#### 1. **MainScaffold**
Scaffold principal con:
- AppBar
- Sidebar
- Navegación
- Tema

#### 2. **PersistentSidebar**
Sidebar persistente con:
- Menú de navegación
- Estado colapsado/expandido
- Persistencia de estado

#### 3. **SucursalSelector**
Selector de sucursal activa:
- Listado de sucursales
- Cambio de sucursal
- Indicador visual

---

## 📱 Pantallas y Funcionalidades

### 1. Splash Screen
- Verificación de token existente
- Redirección automática
- Pantalla de carga

### 2. Login Screen
- Formulario de autenticación
- Validación de campos
- Manejo de errores
- Redirección al dashboard

### 3. Home Screen (Dashboard)
Pantalla principal con:
- **Módulos principales**:
  - Estimaciones
  - Pautas
  - Mapeo
  - Conteo
  - Parámetros
  - Producción
  - Riego
  - Actividades
- **Acciones rápidas**
- **Información del usuario**
- **Selector de sucursal**

### 4. Estimaciones Screen
Dashboard de estimaciones con:
- **Vista general**: Especies agrupadas, totales
- **Filtros**: Por especie, variedad, temporada
- **Vista detallada**: Información completa de cuartel
- **Gráficos**: Visualización de datos
- **Exportación**: Exportar a Excel

### 5. Pautas Screens

#### Pautas Gestión Screen
- Listado de pautas
- Filtros por temporada
- Crear nueva pauta
- Editar pauta existente

#### Pautas Crear Nueva Screen
- Formulario de creación
- Selección de configuración
- Parámetros de pauta

#### Pautas Formulario Screen
- Formulario dinámico
- Campos según tipo de conteo
- Validación de datos

#### Pautas Configuración Screen
- Configuraciones de pauta
- Asociaciones labor-especie
- Gestión de configuraciones

### 6. Mapeo Screen
- Visualización de mapeos
- Filtros por cuartel, fecha
- Información detallada

### 7. Conteo Screens

#### Conteo Atributo Especie Screen
- Conteo por atributo y especie
- Filtros y búsqueda
- Visualización de resultados

#### Conteo Atributo Optimo Screen
- Atributos óptimos
- Configuración de parámetros
- Gestión de valores

#### Manejo Parámetros Conteo Screen
- Parámetros de conteo
- Configuración de reglas
- Valores óptimos

### 8. Admin Usuarios Screen
Gestión completa de usuarios:
- **Listado de usuarios**: Tabla con búsqueda y filtros
- **Crear usuario**: Formulario completo
- **Editar usuario**: Actualización de datos
- **Asignar permisos**: Gestión de permisos
- **Asignar sucursales**: Gestión de acceso
- **Asignar aplicaciones**: Gestión de apps

### 9. Parámetros Screen
- Configuración de parámetros del sistema
- Gestión de opciones generales

### 10. Producción Screen
- Reportes de producción
- Estadísticas
- Visualización de datos

### 11. Riego Screen
- Gestión de riego (en desarrollo)

### 12. Actividades Screen
- Gestión de actividades (en desarrollo)

### 13. Cambiar Clave Screen
- Formulario de cambio de contraseña
- Validación de contraseña actual
- Confirmación de nueva contraseña

### 14. Cambiar Sucursal Screen
- Listado de sucursales disponibles
- Selección de sucursal activa
- Confirmación de cambio

---

## 🎨 Temas y UI

### Paleta de Colores

```dart
Primary: #2E7D32 (Verde oscuro)
Primary Light: #4CAF50 (Verde medio)
Primary Dark: #1B5E20 (Verde muy oscuro)
Accent: #66BB6A (Verde claro)
Success: #4CAF50
Error: #F44336
Warning: #FF9800
Info: #2196F3
```

### Tema Claro y Oscuro

La aplicación soporta dos temas:
- **Tema Claro**: Colores claros, fondo blanco
- **Tema Oscuro**: Colores oscuros, fondo negro

El cambio de tema se persiste en `shared_preferences`.

### Componentes UI

- **Material Design**: Componentes Material de Flutter
- **Responsive**: Adaptable a diferentes tamaños de pantalla
- **Accesibilidad**: Soporte para lectores de pantalla
- **Animaciones**: Transiciones suaves entre pantallas

---

## 🔌 Integración con API

### Autenticación

```dart
// Login
final response = await AuthService.login(usuario, clave);

// Token almacenado automáticamente
// Se incluye en todas las peticiones mediante HttpInterceptor
```

### Peticiones HTTP

```dart
// Ejemplo de petición
final response = await http.get(
  Uri.parse('${ApiConfig.cuartelesUrl}/cuarteles'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

### Manejo de Errores

El `HttpInterceptor` maneja automáticamente:
- Errores 401 (No autorizado): Redirección a login
- Errores 403 (Prohibido): Mensaje de error
- Errores 500 (Error del servidor): Mensaje genérico
- Refresh automático de token expirado

---

## 💻 Desarrollo

### Instalación Local

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd PORTAL_WEB_FRONTEND
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**
   ```bash
   # Crear archivo .env
   echo "API_BASE_URL=https://api-url.com/api" > .env
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run -d chrome
   ```

### Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run -d chrome

# Build para producción
flutter build web

# Análisis de código
flutter analyze

# Formatear código
flutter format lib/
```

### Estructura de Código

#### Ejemplo de Pantalla

```dart
class MiPantalla extends StatefulWidget {
  const MiPantalla({super.key});

  @override
  State<MiPantalla> createState() => _MiPantallaState();
}

class _MiPantallaState extends State<MiPantalla> {
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Mi Pantalla',
      body: Center(
        child: Text('Contenido'),
      ),
    );
  }
}
```

#### Ejemplo de Provider

```dart
class MiProvider extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  Future<void> cargarDatos() async {
    _loading = true;
    notifyListeners();
    
    // Lógica de carga
    
    _loading = false;
    notifyListeners();
  }
}
```

---

## 🚀 Despliegue

### Firebase Hosting

La aplicación está desplegada en Firebase Hosting:

1. **Configurar Firebase**
   ```bash
   firebase login
   firebase init hosting
   ```

2. **Build para producción**
   ```bash
   flutter build web --release
   ```

3. **Desplegar**
   ```bash
   firebase deploy --only hosting
   ```

### URLs de Producción

- **Principal**: `https://portal-web.lahornilla.cl`
- **Firebase**: `https://front-portalweb.web.app`
- **Firebase Alt**: `https://front-portalweb.firebaseapp.com`

### Configuración de Firebase

El archivo `firebase.json` configura el hosting:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## 📊 Características Avanzadas

### Gráficos y Visualizaciones

La aplicación utiliza `fl_chart` para:
- Gráficos de líneas
- Gráficos de barras
- Gráficos circulares
- Visualización de tendencias

### Exportación de Datos

Soporte para exportar datos a:
- **Excel**: Utilizando el paquete `excel`
- **CSV**: Formato de texto plano
- **PDF**: (En desarrollo)

### Tablas de Datos

Utiliza `data_table_2` para:
- Tablas con paginación
- Ordenamiento
- Filtrado
- Búsqueda

### Almacenamiento Local

- **Tokens JWT**: `flutter_secure_storage`
- **Preferencias**: `shared_preferences`
- **Tema**: Persistencia de tema seleccionado
- **Sucursal**: Persistencia de sucursal activa

---

## 🔒 Seguridad

### Almacenamiento de Tokens

Los tokens JWT se almacenan de forma segura usando `flutter_secure_storage`, que utiliza:
- **iOS**: Keychain
- **Android**: Keystore
- **Web**: LocalStorage (con encriptación)

### Validación de Datos

- Validación de formularios
- Sanitización de inputs
- Validación de tipos

### Manejo de Errores

- Mensajes de error amigables
- Logging de errores
- Manejo de excepciones

---

## 📝 Notas Adicionales

### Navegación

La aplicación utiliza navegación basada en rutas con:
- Rutas nombradas
- Parámetros de ruta
- Navegación con contexto

### Responsive Design

La aplicación es responsive y se adapta a:
- Desktop (1920px+)
- Tablet (768px - 1919px)
- Mobile (320px - 767px)

### Internacionalización

Soporte para múltiples idiomas (preparado para):
- Español (actual)
- Inglés (futuro)

---

## 🐛 Troubleshooting

### Problemas Comunes

**Error de conexión a API**
- Verificar URL en `.env`
- Verificar que el servidor esté corriendo
- Revisar CORS en el backend

**Error de autenticación**
- Verificar credenciales
- Limpiar storage local
- Revisar token de autorización

**Problemas de tema**
- Verificar configuración en `app_theme.dart`
- Reiniciar la aplicación
- Limpiar cache del navegador

---

## 📞 Soporte

Para más información o soporte técnico, contactar al equipo de desarrollo.

---

**Versión**: 1.0.0  
**Última actualización**: Diciembre 2024  
**Desarrollado con**: Flutter 3.0+, Dart 3.2.3+


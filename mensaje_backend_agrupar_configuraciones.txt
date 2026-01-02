# 🎯 **SOLICITUD DE ENDPOINT PARA AGRUPAR CONFIGURACIONES POR TIPO DE CONTEO**

---

## 📋 **SOLICITUD ESPECÍFICA**

Hola equipo Backend,

Necesitamos un **nuevo endpoint** para agrupar las configuraciones de pautas por tipo de conteo (labor-especie) para mejorar la experiencia de usuario en el frontend.

---

## 🎯 **ENDPOINT SOLICITADO**

### **📊 Agrupar Configuraciones por Tipo de Conteo**
```http
GET /api/pautas/configuraciones-agrupadas
Authorization: Bearer {token}
```

**Propósito:** Obtener configuraciones agrupadas por tipo de conteo (labor-especie) para mostrar una vista jerárquica en el frontend.

---

## 📊 **ESTRUCTURA DE RESPUESTA ESPERADA**

```json
{
  "success": true,
  "message": "Configuraciones agrupadas obtenidas exitosamente",
  "data": {
    "tipos_conteo": [
      {
        "id_conteotipo": 1,
        "nombre_labor": "RALEO",
        "nombre_especie": "NECTARIN",
        "total_configuraciones": 3,
        "configuraciones": [
          {
            "id": 1,
            "id_empresa": 1,
            "id_conteotipo": 1,
            "id_atributo": 2,
            "id_tipoplanta": "4",
            "nombre_atributo": "FRUTOS",
            "nombre_tipo_planta": "Tipo 4"
          },
          {
            "id": 2,
            "id_empresa": 1,
            "id_conteotipo": 1,
            "id_atributo": 2,
            "id_tipoplanta": "3",
            "nombre_atributo": "FRUTOS",
            "nombre_tipo_planta": "Tipo 3"
          },
          {
            "id": 3,
            "id_empresa": 1,
            "id_conteotipo": 1,
            "id_atributo": 2,
            "id_tipoplanta": "2",
            "nombre_atributo": "FRUTOS",
            "nombre_tipo_planta": "Tipo 2"
          }
        ]
      },
      {
        "id_conteotipo": 2,
        "nombre_labor": "PODA",
        "nombre_especie": "CEREZA",
        "total_configuraciones": 2,
        "configuraciones": [
          {
            "id": 4,
            "id_empresa": 2,
            "id_conteotipo": 2,
            "id_atributo": 1,
            "id_tipoplanta": "1",
            "nombre_atributo": "PESO",
            "nombre_tipo_planta": "Tipo 1"
          },
          {
            "id": 5,
            "id_empresa": 2,
            "id_conteotipo": 2,
            "id_atributo": 6,
            "id_tipoplanta": "1",
            "nombre_atributo": "CARGADORES",
            "nombre_tipo_planta": "Tipo 1"
          }
        ]
      }
    ],
    "total_tipos_conteo": 2,
    "total_configuraciones": 5
  }
}
```

---

## 🔍 **LÓGICA DE AGRUPACIÓN**

### **Agrupar por:**
- `id_conteotipo` (ID del tipo de conteo)
- `nombre_labor` + `nombre_especie` (combinación labor-especie)

### **Datos incluidos por grupo:**
- **Información del tipo de conteo:** `id_conteotipo`, `nombre_labor`, `nombre_especie`
- **Conteo:** `total_configuraciones` en ese grupo
- **Configuraciones:** Array completo de configuraciones para ese tipo de conteo

### **Datos incluidos por configuración:**
- **IDs:** `id`, `id_empresa`, `id_conteotipo`, `id_atributo`, `id_tipoplanta`
- **Nombres:** `nombre_atributo`, `nombre_tipo_planta`

---

## 🎯 **CASOS DE USO EN EL FRONTEND**

### **1. Vista Principal:**
```
🔧 RALEO - NECTARIN (3 configuraciones)     [▼]
🔧 PODA - CEREZA (2 configuraciones)         [▼]
🔧 CONTEO - MANZANA (1 configuración)        [▼]
```

### **2. Vista Expandida:**
```
🔧 RALEO - NECTARIN (3 configuraciones)     [🗑️] [▲]
   ID: 1 | Empresa: 1
   
   Atributo:        FRUTOS
   Labor:           RALEO
   Especie:         NECTARIN
   Tipo de Planta:  Tipo 4
   ID Configuración: 1
   ID Empresa:       1
   ID Conteo Tipo:   1
   
   ─────────────────────────────────────────
   
   Atributo:        FRUTOS
   Labor:           RALEO
   Especie:         NECTARIN
   Tipo de Planta:  Tipo 3
   ID Configuración: 2
   ID Empresa:       1
   ID Conteo Tipo:   1
   
   ─────────────────────────────────────────
   
   Atributo:        FRUTOS
   Labor:           RALEO
   Especie:         NECTARIN
   Tipo de Planta:  Tipo 2
   ID Configuración: 3
   ID Empresa:       1
   ID Conteo Tipo:   1
```

---

## 🔧 **IMPLEMENTACIÓN SUGERIDA**

### **SQL Query:**
```sql
SELECT 
    cp.id_conteotipo,
    le.nombre_labor,
    le.nombre_especie,
    COUNT(cp.id) as total_configuraciones,
    JSON_ARRAYAGG(
        JSON_OBJECT(
            'id', cp.id,
            'id_empresa', cp.id_empresa,
            'id_conteotipo', cp.id_conteotipo,
            'id_atributo', cp.id_atributo,
            'id_tipoplanta', cp.id_tipoplanta,
            'nombre_atributo', a.nombre,
            'nombre_tipo_planta', COALESCE(tp.nombre, 'Sin tipo')
        )
    ) as configuraciones
FROM conteo_dim_configpauta cp
JOIN conteo_pivot_labor_especie le ON cp.id_conteotipo = le.id
JOIN conteo_dim_atributocultivo a ON cp.id_atributo = a.id
LEFT JOIN mapeo_dim_tipoplanta tp ON cp.id_tipoplanta = tp.id
GROUP BY cp.id_conteotipo, le.nombre_labor, le.nombre_especie
ORDER BY le.nombre_labor, le.nombre_especie;
```

### **Python Flask Route:**
```python
@pautas_bp.route('/configuraciones-agrupadas', methods=['GET'])
@jwt_required()
def get_configuraciones_agrupadas():
    try:
        # Obtener configuraciones agrupadas por tipo de conteo
        query = """
        SELECT 
            cp.id_conteotipo,
            le.nombre_labor,
            le.nombre_especie,
            COUNT(cp.id) as total_configuraciones,
            JSON_ARRAYAGG(
                JSON_OBJECT(
                    'id', cp.id,
                    'id_empresa', cp.id_empresa,
                    'id_conteotipo', cp.id_conteotipo,
                    'id_atributo', cp.id_atributo,
                    'id_tipoplanta', cp.id_tipoplanta,
                    'nombre_atributo', a.nombre,
                    'nombre_tipo_planta', COALESCE(tp.nombre, 'Sin tipo')
                )
            ) as configuraciones
        FROM conteo_dim_configpauta cp
        JOIN conteo_pivot_labor_especie le ON cp.id_conteotipo = le.id
        JOIN conteo_dim_atributocultivo a ON cp.id_atributo = a.id
        LEFT JOIN mapeo_dim_tipoplanta tp ON cp.id_tipoplanta = tp.id
        GROUP BY cp.id_conteotipo, le.nombre_labor, le.nombre_especie
        ORDER BY le.nombre_labor, le.nombre_especie
        """
        
        result = db.session.execute(text(query))
        tipos_conteo = []
        total_configuraciones = 0
        
        for row in result:
            configuraciones = json.loads(row.configuraciones) if row.configuraciones else []
            tipos_conteo.append({
                'id_conteotipo': row.id_conteotipo,
                'nombre_labor': row.nombre_labor,
                'nombre_especie': row.nombre_especie,
                'total_configuraciones': row.total_configuraciones,
                'configuraciones': configuraciones
            })
            total_configuraciones += row.total_configuraciones
        
        return jsonify({
            'success': True,
            'message': 'Configuraciones agrupadas obtenidas exitosamente',
            'data': {
                'tipos_conteo': tipos_conteo,
                'total_tipos_conteo': len(tipos_conteo),
                'total_configuraciones': total_configuraciones
            }
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error al obtener configuraciones agrupadas: {str(e)}'
        }), 500
```

---

## 🎯 **BENEFICIOS**

### **Para el Frontend:**
- **Vista jerárquica** más intuitiva
- **Agrupación lógica** por tipo de conteo
- **Menos llamadas** al backend
- **Mejor experiencia** de usuario

### **Para el Backend:**
- **Endpoint específico** para esta funcionalidad
- **Datos optimizados** para el frontend
- **Reutilizable** para otras funcionalidades

---

## 📝 **RESUMEN**

**Solicitamos el endpoint:**
- **URL:** `GET /api/pautas/configuraciones-agrupadas`
- **Propósito:** Agrupar configuraciones por tipo de conteo (labor-especie)
- **Respuesta:** Estructura jerárquica con tipos de conteo y sus configuraciones
- **Beneficio:** Vista más intuitiva y organizada en el frontend

**Este endpoint permitirá al frontend mostrar una vista agrupada donde cada tipo de conteo (ej: "RALEO - NECTARIN") se muestra como una card principal, y al expandirla se ven todas las configuraciones específicas de ese tipo de conteo.**

**📅 Fecha**: 25 de Agosto 2025  
**🔧 Versión**: 1.0.0  
**📋 Estado**: ⚠️ ENDPOINT SOLICITADO - REQUIERE IMPLEMENTACIÓN BACKEND

---

## 🚀 **ACCIÓN INMEDIATA**

**Implementar el endpoint `/api/pautas/configuraciones-agrupadas` para permitir la vista agrupada en el frontend.**

**¡Gracias por la implementación!** 🎯

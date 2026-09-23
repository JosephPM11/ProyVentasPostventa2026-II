# Modelo de Datos — Módulo D: Ventas y Postventa

**Versión:** 1.0.0  
**Fecha:** Septiembre 2026  
**Ecosistema:** Microservicio M1 (Ventas / Pedidos) y Microservicio M2 (Postventa)  
**Lineamiento arquitectónico:** Aislamiento estricto de bases de datos (**RNF-07**). M1 y M2 residen en esquemas/bases de datos independientes y desacopladas; la comunicación e intercambio de datos entre módulos se realiza exclusivamente vía APIs REST y eventos de dominio.

---

## 1. Diagrama Entidad-Relación Lógico

```text
[ ESQUEMA M1: VENTAS ]
┌─────────────────────────┐       1..N       ┌─────────────────────────┐
│         Pedido          │─────────────────<│      DetallePedido      │
│                         │                  └─────────────────────────┘
│  (contacto, cupon,      │       1..N       ┌─────────────────────────┐
│   envio, pago)          │─────────────────<│     HistorialEstado     │
└─────────────────────────┘                  └─────────────────────────┘
             │ 1
             │
             │ 0..1 (condicional)
             ▼
┌─────────────────────────┐
│   SolicitudAnulacion    │
└─────────────────────────┘

────────────────────────────────────────────────────────────────────────
                   (LÍMITE DE MICROSERVICIOS / API)
────────────────────────────────────────────────────────────────────────

[ ESQUEMA M2: POSTVENTA ]
┌─────────────────────────┐       1..N       ┌─────────────────────────┐
│       Devolucion        │─────────────────<│    DetalleDevolucion    │
│  (pedido_id referencial)│                  └─────────────────────────┘
└─────────────────────────┘       1..N       ┌─────────────────────────┐
             │ 0..1                          │   EvidenciaDevolucion   │
             │                               └─────────────────────────┘
             ▼
┌─────────────────────────┐                  ┌─────────────────────────┐
│        Reembolso        │                  │      EncuestaCSAT       │
│ (idempotente: F2/F3/Log)│                  │  (pedido_id referencial)│
└─────────────────────────┘                  └─────────────────────────┘
                                             ┌─────────────────────────┐
                                             │         Reclamo         │
                                             │ (SLA 15 días, respuesta)│
                                             └─────────────────────────┘
```

---

## 2. Esquema M1: Ventas (Pedidos)

### 2.1. Tabla / Colección: `pedidos`
Entidad principal del microservicio transaccional M1. Almacena la cabecera de la compra con la estructura obligatoria de captura.

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Identificador único (UUID o formato correlativo `PED-YYYY-XXXXX`). Clave Primaria. |
| `canal` | VARCHAR(20) | NO | Canal de origen: `CHATBOT`, `MARKETPLACE`, `RETAIL`. |
| `estado` | VARCHAR(20) | NO | Estado actual del pedido: `CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`. |
| `cliente_id` | VARCHAR(36) | NO | Identificador externo del cliente (proveniente del Módulo G de Seguridad). |
| `contacto` | JSON / EMBEDDED | NO | Datos de contacto: `{ nombreCompleto, tipoDocumento, numeroDocumento, telefono, email }`. |
| `envio` | JSON / EMBEDDED | NO | Datos de despacho: `{ modalidad, costo, destinatario, departamento, provincia, distrito, direccion, referencia }`. |
| `pago` | JSON / EMBEDDED | NO | Condiciones de pago: `{ metodoPago, moneda, subtotal, descuentoCupon, costoEnvio, total, transaccionPasarelaId }`. |
| `cupon` | JSON / EMBEDDED | SÍ | Datos de cupón: `{ codigo, descuento, aplicado }`. Nulo si no aplicó cupón. |
| `fecha_creacion` | TIMESTAMP (UTC) | NO | Fecha y hora en que se creó el pedido en el canal. |
| `fecha_actualizacion` | TIMESTAMP (UTC) | NO | Última modificación de estado o datos. |

---

### 2.2. Tabla / Colección: `detalles_pedido`
Líneas de producto adquiridas dentro del pedido (snapshot de compra).

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Identificador único del ítem. Clave Primaria. |
| `pedido_id` | VARCHAR(36) | NO | Llave foránea hacia `pedidos.id`. |
| `producto_id` | VARCHAR(36) | NO | Identificador del producto en el Módulo F (Productos). |
| `sku` | VARCHAR(50) | NO | Código de inventario único al momento de la venta. |
| `descripcion` | VARCHAR(200) | NO | Nombre o descripción histórica del producto. |
| `cantidad` | INTEGER | NO | Unidades solicitadas (debe ser > 0). |
| `precio_unitario` | DECIMAL(12,2) | NO | Precio de venta congelado al momento de crear el pedido. |
| `subtotal` | DECIMAL(12,2) | NO | `cantidad * precio_unitario`. |

---

### 2.3. Tabla / Colección: `historial_estados`
Bitácora inmutable de auditoría para trazabilidad (**RNF-03**). Cada cambio de estado genera un registro.

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Identificador único del registro de auditoría. |
| `pedido_id` | VARCHAR(36) | NO | Llave foránea hacia `pedidos.id`. |
| `estado_anterior` | VARCHAR(20) | SÍ | Estado previo (nulo para el evento inicial de creación). |
| `estado_nuevo` | VARCHAR(20) | NO | Nuevo estado alcanzado (`CREADO`, `PAGADO`, `ANULADO`, etc.). |
| `actor` | VARCHAR(50) | NO | Identificador del sistema o usuario: `CANAL_CHATBOT`, `PASARELA_PAGOS`, `SISTEMA_LOGISTICA`, `GESTOR-XX`, `CLIENTE`. |
| `motivo` | VARCHAR(50) | NO | Código tipificado del cambio. Para anulaciones automáticas: **`PAGO_NO_COMPLETADO`**, `ERROR_SELECCION_PRODUCTO`, `ENTREGA_FALLIDA_DEFINITIVA`. |
| `comentario` | TEXT | SÍ | Observaciones adicionales o mensaje descriptivo de la transición. |
| `fecha_cambio` | TIMESTAMP (UTC) | NO | Timestamp exacto en UTC del cambio de estado. |

---

### 2.4. Tabla / Colección: `solicitudes_anulacion`
Gestión de anulaciones condicionales que requieren autorización de Gestor (F2).

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Identificador de la solicitud correlativa (`ANUL-XXXX`). Clave Primaria. |
| `pedido_id` | VARCHAR(36) | NO | Llave foránea hacia `pedidos.id`. |
| `estado_solicitud` | VARCHAR(20) | NO | `PENDIENTE`, `APROBADA`, `RECHAZADA`. |
| `motivo` | VARCHAR(50) | NO | Motivo tipificado de la anulación. |
| `solicitado_por` | VARCHAR(50) | NO | `CLIENTE` o identificador del canal. |
| `autorizado_por` | VARCHAR(50) | SÍ | Identificador del Gestor que resolvió la solicitud (nulo mientras esté `PENDIENTE`). |
| `fundamento_rechazo`| TEXT | SÍ | Justificación obligatoria en caso de ser rechazada por el Gestor. |
| `fecha_solicitud` | TIMESTAMP (UTC) | NO | Fecha y hora de creación de la solicitud. |
| `fecha_resolucion` | TIMESTAMP (UTC) | SÍ | Fecha y hora de dictamen del Gestor. |

---

## 3. Esquema M2: Postventa

### 3.1. Tabla / Colección: `devoluciones`
Expedientes de cambios o devoluciones posteriores a la entrega (F3). No modifica tablas de M1; valida contra F1 por API.

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Identificador del expediente (`DEV-YYYY-XXXX`). Clave Primaria. |
| `pedido_id` | VARCHAR(36) | NO | Identificador referencial del pedido entregado en M1. |
| `cliente_id` | VARCHAR(36) | NO | Identificador del cliente solicitante. |
| `tipo` | VARCHAR(20) | NO | `CAMBIO` o `DEVOLUCION_DINERO`. |
| `estado` | VARCHAR(20) | NO | `SOLICITADA`, `EN_EVALUACION`, `APROBADA`, `RECHAZADA`, `COMPLETADA`. |
| `motivo` | VARCHAR(50) | NO | Motivo tipificado: `PRODUCTO_DEFECTUOSO`, `TALLA_INCORRECTA`, `DISCONFORMIDAD`. |
| `descripcion` | TEXT | NO | Explicación del problema por parte del cliente. |
| `autorizador_id` | VARCHAR(50) | SÍ | Identificador del Gestor que aprueba o rechaza. |
| `fundamento_rechazo`| TEXT | SÍ | **Obligatorio** si el estado es `RECHAZADA`. |
| `fecha_registro` | TIMESTAMP (UTC) | NO | Timestamp UTC de creación de la solicitud. |
| `fecha_resolucion` | TIMESTAMP (UTC) | SÍ | Timestamp UTC de resolución del Gestor. |

---

### 3.2. Tabla / Colección: `evidencias_devolucion`
Archivos visuales adjuntos a un expediente de devolución (obligatorio en motivos de falla de fábrica).

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Clave Primaria. |
| `devolucion_id` | VARCHAR(36) | NO | Llave foránea hacia `devoluciones.id`. |
| `tipo` | VARCHAR(20) | NO | `IMAGEN`, `VIDEO`, `DOCUMENTO`. |
| `url` | VARCHAR(500) | NO | Enlace al repositorio de almacenamiento de la evidencia. |
| `fecha_subida` | TIMESTAMP (UTC) | NO | Fecha de carga del archivo. |

---

### 3.3. Tabla / Colección: `reembolsos`
Transacciones monetarias de extorno hacia pasarelas o clientes (F4). Cumple con **RNF-08: Idempotencia**.

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Identificador del reembolso (`REEM-XXXXX`). Clave Primaria. |
| `idempotency_key` | VARCHAR(100) | NO | Clave única de idempotencia (`X-Idempotency-Key`). Índice Único. |
| `origen` | VARCHAR(30) | NO | Entidad originadora autorizada: `ANULACION` (F2), `DEVOLUCION` (F3), `DESPACHO_FALLIDO` (Módulo E). |
| `referencia_id` | VARCHAR(36) | NO | Identificador del pedido o expediente que origina el reembolso. |
| `monto` | DECIMAL(12,2) | NO | Monto a devolver (nunca puede exceder el pago original). |
| `moneda` | VARCHAR(3) | NO | Moneda de la transacción (`PEN`, `USD`). |
| `estado` | VARCHAR(20) | NO | `PENDIENTE`, `EXITOSO`, `FALLIDO`. |
| `transaccion_pasarela_id` | VARCHAR(100) | SÍ | Identificador retornado por el simulador de pagos. |
| `solicitado_por` | VARCHAR(50) | NO | Actor o sistema solicitante (`SISTEMA_F2`, `SISTEMA_F3`, `MODULO_DESPACHO_E`). |
| `fecha_ejecucion` | TIMESTAMP (UTC) | NO | Timestamp UTC en que se procesó el movimiento monetario. |

---

### 3.4. Tabla / Colección: `encuestas_csat`
Métricas de satisfacción capturadas tras la entrega (F5).

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Clave Primaria. |
| `pedido_id` | VARCHAR(36) | NO | Identificador referencial del pedido. Índice Único (1 encuesta por pedido). |
| `cliente_id` | VARCHAR(36) | NO | Identificador del cliente encuestado. |
| `canal` | VARCHAR(20) | NO | Canal donde se respondió: `CHATBOT`, `WEB`, `EMAIL`. |
| `puntuacion` | SMALLINT | NO | Valor numérico entero del 1 al 5. |
| `comentario` | TEXT | SÍ | Feedback opcional del cliente. |
| `fecha_registro` | TIMESTAMP (UTC) | NO | Fecha y hora en que se completó la encuesta. |

---

### 3.5. Tabla / Colección: `reclamos`
Libro de Reclamaciones normativo según Indecopi con control de SLA y respuesta al consumidor (F6 / **A10**).

| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | VARCHAR(36) | NO | Identificador interno único. Clave Primaria. |
| `codigo_seguimiento`| VARCHAR(20) | NO | Código visible para el usuario (`REC-YYYY-XXXXX`). Índice Único. |
| `pedido_id` | VARCHAR(36) | SÍ | Identificador del pedido referencial (opcional si es queja de servicio general). |
| `tipo` | VARCHAR(20) | NO | Clasificación legal: `RECLAMO` o `QUEJA`. |
| `canal` | VARCHAR(20) | NO | Canal de ingreso: `CHATBOT`, `WEB`, `RETAIL`. |
| `estado` | VARCHAR(20) | NO | Estados: `REGISTRADO`, `EN_PROCESO`, `ATENDIDO`, `DERIVADO`. |
| `motivo` | VARCHAR(50) | NO | Motivo tipificado: `INCUMPLIMIENTO_PLAZO_ENTREGA`, `PRODUCTO_DEFECTUOSO_O_INCORRECTO`, `COBRO_INDEBIDO_O_NO_RECONOCIDO`, `ATENCION_INADECUADA`, `INCUMPLIMIENTO_GARANTIA`. |
| `detalle` | TEXT | NO | Explicación del reclamo o queja por parte del consumidor. |
| `datos_consumidor` | JSON / EMBEDDED | NO | Datos del reclamante: `{ nombreCompleto, documento, email, telefono }`. |
| `plazo_dias_habiles`| INTEGER | NO | Plazo legal normado por Indecopi: valor fijo **15**. |
| `fecha_limite_sla` | TIMESTAMP (UTC) | NO | Fecha y hora límite calculada para atender el reclamo sin violar el SLA. |
| `respuesta_visible_cliente` | TEXT | SÍ | **Respuesta formal dictaminada por el Gestor** visible para el consumidor. Requerido para transicionar a `ATENDIDO`. |
| `atendido_por` | VARCHAR(50) | SÍ | Identificador del Gestor que emitió la resolución. |
| `fecha_registro` | TIMESTAMP (UTC) | NO | Timestamp UTC de creación del reclamo. |
| `fecha_atencion` | TIMESTAMP (UTC) | SÍ | Timestamp UTC de cierre y emisión de respuesta formal. |

---

## 4. Estrategia de Aislamiento e Integridad

1. **Sin Llaves Foráneas Cruzadas:** No existen restricciones de integridad referencial (`FOREIGN KEY`) a nivel de base de datos entre tablas de M1 (`pedidos`) y tablas de M2 (`devoluciones`, `reembolsos`, `reclamos`). Toda validación de coherencia se realiza a través del API REST de F1.
2. **Inmutabilidad Financiera y de Auditoría:** Las tablas `historial_estados` y `reembolsos` son de tipo *Append-Only* (solo inserción); los registros nunca se actualizan ni se eliminan una vez persistidos.
3. **Control de Duplicidad:** El índice único sobre `reembolsos.idempotency_key` garantiza que peticiones repetidas desde la red nunca generen duplicidad de extornos contables (**RNF-08**).

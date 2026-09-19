# API Contract — F1: Ciclo de vida del pedido

**Microservicio:** M1 — Pedidos
**Recurso principal:** `Pedido`

## Estados válidos

`CREADO`, `PAGADO`, `EN_PREPARACION`, `DESPACHADO`, `ENTREGADO`, `ANULADO`

## Máquina de estados (transiciones permitidas)

```
CREADO ──────► PAGADO ──────► EN_PREPARACION ──────► DESPACHADO ──────► ENTREGADO
  │               │
  └──► ANULADO ◄──┘   (EN_PREPARACION → ANULADO requiere autorización del Gestor, ver F2)
```

Cualquier transición que no esté dibujada arriba se rechaza con `409 Conflict`. A partir de `DESPACHADO` ya no es posible anular (el camino pasa a ser una devolución, F3).

## Recurso: Pedido

### POST /api/pedidos

Crea un nuevo pedido (estado inicial: `CREADO`). Antes de persistir, valida precio y disponibilidad contra el módulo de Productos y Ofertas (F).

**Roles permitidos:** canal autenticado (A/B/C).

**Request body:**
```json
{
  "canal": "MARKETPLACE | CHATBOT | RETAIL",
  "clienteId": "string",
  "vendedorId": "string | null",
  "items": [
    { "productoId": "string", "sku": "string", "cantidad": 1, "precioUnitario": 0.0 }
  ],
  "direccionEntregaId": "string",
  "moneda": "PEN"
}
```

**Response 201:**
```json
{
  "pedidoId": "string",
  "codigo": "string",
  "estado": "CREADO",
  "canal": "MARKETPLACE",
  "subtotal": 0.0,
  "descuento": 0.0,
  "total": 0.0,
  "fechaCreacion": "2026-09-12T10:00:00Z"
}
```

**Errores:**
- `400 Bad Request` — estructura inválida, ítems vacíos o dirección de entrega faltante.
- `409 Conflict` — algún ítem no tiene disponibilidad/precio válido en Productos (F).

---

### GET /api/pedidos/{pedidoId}

Devuelve el detalle, el estado actual y el historial completo del pedido.

**Roles permitidos:** canal que originó el pedido, o Gestor.

**Response 200:**
```json
{
  "pedidoId": "string",
  "codigo": "string",
  "clienteId": "string",
  "canal": "MARKETPLACE",
  "estado": "CREADO | PAGADO | EN_PREPARACION | DESPACHADO | ENTREGADO | ANULADO",
  "items": [
    { "productoId": "string", "sku": "string", "cantidad": 1, "precioUnitario": 0.0, "importe": 0.0 }
  ],
  "pago": { "metodo": "string", "estado": "string", "monto": 0.0 },
  "historialEstados": [
    { "estadoAnterior": null, "estadoNuevo": "CREADO", "actor": "string", "motivo": null, "fechaHora": "2026-09-12T10:00:00Z" }
  ],
  "subtotal": 0.0,
  "descuento": 0.0,
  "total": 0.0
}
```

**Errores:**
- `404 Not Found` — pedido no encontrado.

---

### GET /api/pedidos?clienteId={id}&estado={estado}

Lista pedidos filtrados por cliente y/o estado (para el frontend de canal y para F6 — Dashboard).

**Response 200:**
```json
{
  "pedidos": [ /* array de objetos Pedido resumidos, mismo shape que GET individual */ ],
  "total": 0
}
```

---

### PATCH /api/pedidos/{pedidoId}/estado

Cambia el estado del pedido siguiendo la máquina de estados. Es el **único** endpoint autorizado a mutar el estado — lo usan tanto el propio frontend/backend de M1 como módulos externos:

- **Despacho y Entrega (E)** lo llama para notificar `DESPACHADO` y `ENTREGADO` (o el evento de entrega fallida).
- **F2 (Anulación)** lo llama para transicionar a `ANULADO`, previa autorización del Gestor si el pedido está `EN_PREPARACION`.

**Request body:**
```json
{
  "nuevoEstado": "ENTREGADO",
  "actor": "modulo-despacho-entrega",
  "motivo": "string | null",
  "claveIdempotencia": "string"
}
```

**Response 200:** pedido actualizado (mismo shape que GET).

**Errores:**
- `400 Bad Request` — `nuevoEstado` no reconocido.
- `403 Forbidden` — el actor no tiene permiso para esa transición (ej. anular `EN_PREPARACION` sin autorización del Gestor).
- `404 Not Found` — pedido no encontrado.
- `409 Conflict` — la transición no está permitida desde el estado actual.

**Idempotencia:** si `claveIdempotencia` ya fue procesada para ese pedido, el sistema retorna `200 OK` con el estado actual sin duplicar el historial ni volver a publicar el evento (relevante para reintentos del evento de entrega de Despacho).

---

## Eventos publicados por F1

| Evento | Disparador | Consumidores |
|---|---|---|
| `pedido.pagado` | Transición `CREADO → PAGADO` | M2 (agregados), F6 |
| `pedido.anulado` | Transición `→ ANULADO` | Productos (F, reposición de stock), F4 (si hubo pago), F6 |
| `pedido.entregado` | Transición `EN_PREPARACION/DESPACHADO → ENTREGADO` (confirmado por Despacho) | F5 (encuesta), F6 (agregados) |

Cada evento incluye `pedidoId`, `estadoAnterior`, `estadoNuevo`, `actor` y `fechaHora`. Los consumidores deben ser idempotentes ante reprocesamiento.

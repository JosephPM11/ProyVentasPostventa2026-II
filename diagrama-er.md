# Correcciones Pendientes — Diagrama ER

### 1. Arquitectura y Aislamiento (RNF-07)
- **Problema:** Hay líneas de relación sólidas (FK) entre tablas de M1 y M2[cite: 4].
- **Corrección:** 
  - Separar en dos bloques visuales: **BD M1 (Ventas)** y **BD M2 (Postventa)**.
  - Eliminar conectores continuos que van desde `DEVOLUCION`, `RECLAMO` y `CALIFICACION` hacia `PEDIDO`[cite: 4].
  - Mantener `idPedido` como atributo escalar[cite: 4]. Si se unen, usar solo línea discontinua (`<<referencia API>>`).

---

### 2. Cambios en M1 (Ventas)
* **`PEDIDO`:**
  - Agregar campos de contacto: `nombreContacto`, `tipoDocumento`, `numeroDocumento`, `telefono`, `email`[cite: 2, 4].
  - Agregar campos de envío: `modalidadEnvio`, `costoEnvio`, `destinatario`, `distrito`, `direccion`[cite: 2].
  - Agregar: `codigoCupon` y `creadoEn`[cite: 2, 4].
* **`HISTORIAL_ESTADO`:**
  - Cambiar `idUsuario: int` por **`actor: string`** para soportar `CANAL_CHATBOT` y pasarelas automáticas (A9)[cite: 3, 4].
  - Asegurar que `motivo` acepte `PAGO_NO_COMPLETADO`[cite: 3, 4].

---

### 3. Cambios en M2 (Postventa)
* **`RECLAMO`:**
  - Renombrar `respuesta` por **`respuestaVisibleCliente`** (A10)[cite: 2, 4].
  - Agregar **`motivo: string`**[cite: 2, 4].
  - Agregar datos del consumidor: `nombreConsumidor`, `documento`, `email`, `telefono`[cite: 2, 4].
  - Agregar: `plazoDiasHabiles: int` (15)[cite: 2, 4].
* **`REEMBOLSO`:**
  - Agregar **`idempotencyKey: string`** (RNF-08)[cite: 4].
  - Agregar **`estado: string`** (`PENDIENTE`, `EXITOSO`, `FALLIDO`)[cite: 4].
  - Quitar FK física hacia `ANULACION` (reside en M1); usar referencia lógica por ID[cite: 4].
  - Limitar `tipoOrigen` únicamente a `'ANULACION'` y `'DEVOLUCION'`[cite: 4].
* **`DEVOLUCION`:**
  - Quitar campo escalar `evidencia` y crear entidad hija **`EVIDENCIA_DEVOLUCION`** (`id`, `idDevolucion`, `url`, `tipo`, `fecha`) en relación 1 a N[cite: 4].
  - Agregar `idAutorizador` y `fundamentoRechazo`[cite: 4].

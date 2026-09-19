# SDD · Documento de Especificaciones Funcionales y de Interfaz

## 1. Módulos y Especificaciones Funcionales

### M1 · VENTAS

#### [F1] Gestión de Pedidos y Estados
* **Requisitos Funcionales:** `RF-01`, `RF-02`, `RF-03`, `RF-04`
* **Wireframes asociados:** `W02`, `W03`
* **Detalle:**
  * **01.** Crear pedido desde canal A/B/C en estado `CREADO`.
  * **02.** Consultar por ID y listar pedidos por cliente.
  * **03.** Validar transiciones de estado y registrar auditoría en `HistorialEstado`.
  * **04.** Publicar eventos de cambios relevantes hacia el bus/mensajería.

#### [F2] Anulación y Despacho
* **Requisitos Funcionales:** `RF-05`, `RF-06`
* **Wireframes asociados:** `W04`
* **Detalle:**
  * **05.** Registrar anulación con motivo obligatorio y autorización correspondiente.
  * **06.** Coordinar actualización de stock, estado de despacho y origen del reembolso.

---

### M2 · POSTVENTA

#### [F3] Devoluciones
* **Requisitos Funcionales:** `RF-07`, `RF-08`
* **Wireframes asociados:** `W05`
* **Detalle:**
  * **07.** Registrar y consultar devolución adjuntando evidencia y estado actual.
  * **08.** Resolver devolución mediante cambio de producto, reembolso monetario o rechazo.

#### [F4] Reembolsos y Extornos
* **Requisitos Funcionales:** `RF-09`, `RF-10`
* **Wireframes asociados:** `W07`
* **Detalle:**
  * **09.** Procesar reembolsos desde un origen válido, garantizando la no duplicidad de transacciones.
  * **10.** Registrar de forma inmutable: monto, moneda, identificador de transacción, actor responsable y marca temporal (fecha/hora).

#### [F5] Encuestas y Métricas CSAT
* **Requisitos Funcionales:** `RF-11`, `RF-12`
* **Wireframes asociados:** `W08`
* **Detalle:**
  * **11.** Disparar encuesta posterior a la entrega: escala de calificación de 1 a 5 y campo opcional de comentario.
  * **12.** Calcular y actualizar métricas CSAT agrupadas por canal de venta y período de tiempo.

#### [F6] Libro de Reclamaciones y Analítica
* **Requisitos Funcionales:** `RF-13`, `RF-14`, `RF-15`, `RF-16`
* **Wireframes asociados:** `W01`, `W06`, `W08`
* **Detalle:**
  * **13.** Registro de reclamo: generación de código único, vinculación opcional a pedido, seguimiento de plazo/SLA y estado.
  * **14.** Generar formato formal de reclamo y almacenar evidencia digital de la atención.
  * **15.** Mantener tablas/vistas agregadas para reportería analítica (evitar consultas que recorran todo el histórico de ventas transaccionales).
  * **16.** Filtrar indicadores analíticos y permitir exportación según alcance del entregable.

---

## 2. Reglas de Negocio Transversales (`RN-01` a `RN-10`)

* **Control de Estados:** Únicamente el módulo **M1 (Ventas)** tiene permisos para modificar estados de pedidos; el sistema debe rechazar transiciones no permitidas o inválidas.
* **Flujo de Anulaciones:**
  * El motivo de anulación es estrictamente obligatorio.
  * Si el pedido está en estado `EN PREPARACIÓN`, exige un permiso/autorización explícita.
  * Si el pedido ya figura como `DESPACHADO`, el proceso se deriva obligatoriamente al flujo de devolución.
* **Criterios de Devolución:** Requiere estado de entrega confirmada y adjunto de evidencia cuando aplique.
* **Disparadores de Extorno:** Válido únicamente ante una anulación pagada o una devolución formalmente aprobada.
* **Atención de Reclamos:** Asignación de código único y cumplimiento estricto de SLA de 15 días hábiles conforme a la guía de atención.
* **Aislamiento de Datos:** Prohibidas las lecturas cruzadas directas de base de datos entre **M1** y **M2**; la reportería debe consumir snapshots o proyecciones desacopladas.
* **Trazabilidad:** Cada especificación funcional `F` enlaza directamente con sus respectivos `RF`, `W` (wireframes) y entidades del modelo de dominio.

---

## 3. Especificaciones de Interfaz y Requisitos No Funcionales (RNF)

| Código | Requisito | Criterio de Aceptación / Verificación |
| :--- | :--- | :--- |
| **RNF-01** | **Performance** | • Creación/consulta de pedido $< 500\text{ ms}$.<br>• Carga de dashboard $< 2\text{ s}$ bajo carga con $\ge 5\,000$ pedidos.<br>• *Verificación:* Pruebas de carga con dataset reproducible. |
| **RNF-02** | **Seguridad** | • Autenticación mediante token válido.<br>• Control de acceso por rol administrativo y validación de propiedad del recurso.<br>• *Verificación:* Pruebas de respuesta `401 Unauthorized` / `403 Forbidden` e intentos con identificadores ajenos. |
| **RNF-03** | **Trazabilidad** | • Auditoría completa de cambios de estado y transacciones de dinero (actor, timestamp, motivo, resultado).<br>• Reclamos auditables por código y SLA.<br>• *Verificación:* Auditoría de registros en BD y centralización de logs. |
| **RNF-04** | **Usabilidad** | • Consola/interfaz completamente responsive.<br>• Manejo claro de mensajes de error y diálogo de confirmación obligatorio para acciones destructivas/irreversibles.<br>• *Verificación:* Revisión de UI contra wireframes aprobados. |
| **RNF-05** | **Disponibilidad** | • Tolerancia a fallos: cero pérdida de transacciones u operaciones críticas.<br>• Mecanismos de reintento automático y encolamiento cuando aplique.<br>• *Verificación:* Pruebas de resiliencia simulando caída de servicios dependientes. |
| **RNF-06** | **Mantenibilidad** | • Repositorio compartido bajo trunk-based o gitflow estricto con revisión obligatoria de Pull Requests (PR).<br>• Contratos de API documentados con OpenAPI / Swagger.<br>• Migraciones de base de datos versionadas y automatizadas. |
| **RNF-07** | **Aislamiento** | • Prohibidas las lecturas cruzadas directas de base de datos entre M1 y M2.<br>• Respeto a los límites de contexto (*Bounded Contexts*) y permisos de acceso por esquema/servicio.<br>• *Verificación:* Inspección de código estático y políticas de base de datos. |
| **RNF-08** | **Idempotencia** | • Garantía de efecto único (*at-most-once/exactly-once processing*) en operaciones críticas de reembolsos y eventos transaccionales.<br>• *Verificación:* Enviar solicitudes duplicadas idénticas y validar que no se procesen cobros/extornos múltiples. |
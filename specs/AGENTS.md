# AGENTS.md — Módulo D: Ventas y Postventa

Instrucciones para agentes de IA (Claude Code, Cursor, Copilot, etc.) que trabajen sobre este
proyecto. Este repo contiene **únicamente especificaciones**; el código vive en los repos
separados de `frontend` y `backend`. Léelo antes de generar o modificar cualquier código.

## Contexto del proyecto

- Proyecto general: Marketplace Multicanal de productos deportivos (arquitectura de microservicios, 7 módulos en paralelo, cada uno de un equipo distinto).
- Este módulo: **Módulo D — Ventas y Postventa**.
- Metodología: Spec-Driven Development (SDD). Toda implementación debe basarse en lo definido en `specs/overview.md` y demás documentos de este repo — nunca inventar comportamiento no especificado.
- Repos involucrados:
  - `specs` (este repo) — fuente de verdad de requerimientos y diseño.
  - `frontend` — repo independiente en GitHub, clonado localmente solo como referencia.
  - `backend` — repo independiente en GitHub, clonado localmente solo como referencia.

## Cómo debe analizar el código un agente

1. Antes de tocar código en `frontend/` o `backend/`, leer `specs/overview.md` y la especificación funcional relacionada con la tarea (ej. F6 — Dashboard y reportes).
2. Si una tarea no tiene spec clara o suficiente, señalarlo explícitamente y proponer un borrador de spec antes de improvisar la implementación.
3. Revisar que los cambios respeten los contratos de API (endpoints, DTOs, esquemas de datos) documentados, ya que frontend y backend deben mantenerse sincronizados entre sí.
4. Tener en cuenta que otros 6 grupos del curso dependen de convenciones de arquitectura compartidas del marketplace general — no asumir libertad total de diseño sin verificar impacto fuera del Módulo D.

## Reglas que debe respetar

- No modificar código fuera del alcance del Módulo D (Ventas y Postventa) sin autorización explícita del equipo.
- No cambiar el stack tecnológico definido (React en frontend; backend y base de datos según lo acordado en `overview.md`) sin aprobación del equipo.
- No mezclar responsabilidades entre repos: código de frontend no se genera dentro de `backend/`, y viceversa.
- Todo cambio en contratos de API o modelo de datos se refleja primero en `specs/`, y recién después en el código.
- Las carpetas `frontend/` y `backend/` dentro de este repo son solo clones locales de referencia (`.gitignore`): un agente nunca debe intentar hacer commit de su contenido en el repo de specs.

## Estilo a seguir

- Nomenclatura de branches: `[definir, ej. feature/f6-dashboard-ventas]`
- Convención de commits: `[definir, ej. Conventional Commits]`
- Linting/formato frontend: `[definir, ej. ESLint + Prettier]`
- Linting/formato backend: `[definir, ej. Checkstyle / Google Java Style]`
- Nombres de endpoints, DTOs y tablas: seguir exactamente lo documentado en `specs/`, sin variaciones libres.

## Qué NO debe modificar sin permiso

- Contratos de API compartidos con otros módulos del marketplace.
- Esquemas de base de datos ya usados por otros servicios o módulos.
- Configuración de despliegue / infraestructura en la nube.
- Documentos de `specs/` ya aprobados por el Product Owner (Joseph) — proponer cambios vía PR, no editar directamente.
- El `.gitignore` raíz que excluye `frontend/` y `backend/`.

## Flujo de trabajo esperado

1. Leer la spec relevante en `specs/`.
2. Implementar o editar en el repo correspondiente (`frontend` o `backend`).
3. Si el comportamiento implementado difiere de lo documentado, actualizar la spec en el mismo cambio.
4. Abrir PR para revisión del equipo (mínimo revisión de Joseph como PO).

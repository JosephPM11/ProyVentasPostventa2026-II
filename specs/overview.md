# Overview — Marketplace Multicanal de Productos Deportivos

## ¿Qué es este proyecto?

Este repositorio es el **repositorio de especificaciones (specs)** del proyecto grupal del curso
**Taller de Construcción de Software Web (TCSW)** — FISI, UNMSM, ciclo 2026-II.

El proyecto general del curso es un **Marketplace Multicanal de productos deportivos**, construido
bajo arquitectura de **microservicios** y desarrollado con enfoque **Spec-Driven Development (SDD)
con apoyo de IA**: las especificaciones que viven aquí son la fuente de verdad que tanto el equipo
como los agentes de IA usan para implementar el código en los repos de `frontend` y `backend`.

El proyecto completo se divide en 7 módulos, cada uno a cargo de un grupo distinto del curso. Este
repositorio documenta específicamente el módulo que le corresponde a nuestro equipo.

## Módulo D — Ventas y Postventa

Responsable del flujo de venta y de la atención posterior a la compra dentro del marketplace:
carrito, checkout, pagos, seguimiento de pedidos, devoluciones/reclamos y reportes de ventas.

## Cómo está organizado el repositorio

Este repo **no contiene código de frontend ni de backend**. Ambos viven en repositorios propios en
GitHub, independientes de este:

| Carpeta local | Contenido | Repo real |
|---|---|---|
| `specs/` | Documentación funcional, técnica y de arquitectura (este repo) | `ProyVentasPostventa2026-II` |
| `frontend/` | Cliente web (React) | `[URL del repo frontend]` |
| `backend/` | Servicios del módulo | `[URL del repo backend]` |

Las carpetas `frontend/` y `backend/` existen a nivel local solo como referencia (son clones de sus
repos reales) y están excluidas del control de versiones de este repo vía `.gitignore`. Es decir:
tres repos independientes en GitHub, conviviendo en una sola carpeta de trabajo local.

## Objetivos del módulo

- Definir y mantener actualizados los requerimientos funcionales y no funcionales de Ventas y Postventa.
- Ser la referencia única para que frontend y backend se implementen de forma consistente entre sí.
- Permitir que agentes de IA generen y mantengan código alineado a estas especificaciones (ver `AGENTS.md`).
- Cumplir los 6 hitos del curso hasta la semana 16 del ciclo.

## Alcance funcional

- **F6 — Dashboard y reportes de ventas** (a cargo de Fabrizio)
- `[completar F1–F5/F7 y demás funcionalidades asignadas dentro del Módulo D]`

## Stack tecnológico

- **Frontend:** React
- **Backend:** `[definir: Java Spring Boot / .NET Core / Node.js]`
- **Base de datos:** `[definir: PostgreSQL / MySQL]`
- **Diseño:** Figma
- **Arquitectura:** Microservicios

## Equipo

| Nombre | Rol / módulo a cargo |
|---|---|
| Joseph | Líder de equipo / Product Owner |
| Fabrizio | F6 — Dashboard y reportes de ventas |
| Johan | `[rol]` |
| Luis | `[rol]` |
| Varillas | `[rol]` |
| Luis Alejandro | `[rol]` |
| Michael | `[rol]` |

## Roadmap

El proyecto avanza en 6 hitos hasta la semana 16 del ciclo.

| Hito | Entregable | Fecha |
|---|---|---|
| 1 | `[ ]` | `[ ]` |
| 2 | `[ ]` | `[ ]` |
| 3 | `[ ]` | `[ ]` |
| 4 | `[ ]` | `[ ]` |
| 5 | `[ ]` | `[ ]` |
| 6 | `[ ]` | `[ ]` |

## Repos relacionados

- Specs (este repo): `ProyVentasPostventa2026-II`
- Frontend: `[link]`
- Backend: `[link]`

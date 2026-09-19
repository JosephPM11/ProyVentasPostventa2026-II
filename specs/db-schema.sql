-- F1: Ciclo de vida del pedido — Microservicio M1
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE pedidos (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo              VARCHAR(20) NOT NULL UNIQUE,
    canal               VARCHAR(20) NOT NULL
                        CHECK (canal IN ('MARKETPLACE', 'CHATBOT', 'RETAIL')),
    cliente_id          VARCHAR(64) NOT NULL,
    vendedor_id         VARCHAR(64),
    estado              VARCHAR(20) NOT NULL DEFAULT 'CREADO'
                        CHECK (estado IN ('CREADO', 'PAGADO', 'EN_PREPARACION', 'DESPACHADO', 'ENTREGADO', 'ANULADO')),
    direccion_entrega_id VARCHAR(64) NOT NULL,
    moneda              VARCHAR(3) NOT NULL DEFAULT 'PEN',
    subtotal            NUMERIC(10,2) NOT NULL DEFAULT 0,
    descuento           NUMERIC(10,2) NOT NULL DEFAULT 0,
    total               NUMERIC(10,2) NOT NULL DEFAULT 0,
    fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE pedido_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id       UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id     VARCHAR(64) NOT NULL,
    sku             VARCHAR(64) NOT NULL,
    descripcion     TEXT,
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    descuento       NUMERIC(10,2) NOT NULL DEFAULT 0,
    importe         NUMERIC(10,2) NOT NULL
);

CREATE TABLE pagos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id       UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    metodo          VARCHAR(30) NOT NULL,
    referencia      VARCHAR(100),
    monto           NUMERIC(10,2) NOT NULL CHECK (monto >= 0),
    estado          VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                    CHECK (estado IN ('PENDIENTE', 'CONFIRMADO', 'RECHAZADO')),
    fecha_proceso   TIMESTAMPTZ
);

CREATE TABLE pedido_historial_estados (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id       UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    estado_anterior VARCHAR(20),
    estado_nuevo    VARCHAR(20) NOT NULL,
    actor           VARCHAR(64) NOT NULL,
    motivo          TEXT,
    clave_idempotencia VARCHAR(100),
    fecha_hora      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pedidos_cliente_id ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_canal ON pedidos(canal);
CREATE INDEX idx_pedido_items_pedido_id ON pedido_items(pedido_id);
CREATE INDEX idx_pagos_pedido_id ON pagos(pedido_id);
CREATE INDEX idx_pedido_historial_pedido_id ON pedido_historial_estados(pedido_id);
CREATE UNIQUE INDEX idx_pedido_historial_idempotencia ON pedido_historial_estados(pedido_id, clave_idempotencia)
    WHERE clave_idempotencia IS NOT NULL;

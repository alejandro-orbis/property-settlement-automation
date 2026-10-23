-- Schema used by the workflows (PostgreSQL 16).
-- Reconstructed from the SQL embedded in the n8n workflows; verified by running
-- those queries against this schema (see docs/architecture.md).
-- Business parameters live in `configuracion` (key/value).

CREATE TABLE configuracion (
    id SERIAL PRIMARY KEY,
    clave TEXT UNIQUE NOT NULL,
    valor TEXT NOT NULL,
    actualizado_en TIMESTAMP DEFAULT now()
);

CREATE TABLE propietarios (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    nif TEXT,
    email TEXT,
    telefono TEXT,
    direccion_fiscal TEXT,
    creado_en TIMESTAMP DEFAULT now()
);

CREATE TABLE propiedades (
    id SERIAL PRIMARY KEY,
    codigo_rentila TEXT UNIQUE,
    direccion TEXT NOT NULL,
    propietario_id INTEGER REFERENCES propietarios(id),
    tipo_gestion_default TEXT,                      -- 'tradicional' | 'habitaciones' | 'turistico'
    cobro_directo_propietario BOOLEAN DEFAULT FALSE, -- owner collects rent; only fees are invoiced
    num_habitaciones INTEGER DEFAULT 0,
    creado_en TIMESTAMP DEFAULT now()
);

CREATE TABLE movimientos (
    id SERIAL PRIMARY KEY,
    propiedad_id INTEGER REFERENCES propiedades(id),  -- NULL for bank expenses until Workflow 2 resolves it
    fecha DATE NOT NULL,
    de_a TEXT,
    monto NUMERIC(10,2) NOT NULL,
    monto_cobrado NUMERIC(10,2),                      -- amount actually collected (partial payments)
    tipo TEXT NOT NULL,                               -- Alquiler | Suministros | Gasto_* | Rotacion_* ...
    descripcion TEXT,
    estado TEXT,
    pagado_en DATE,
    referencia_pago TEXT,
    periodo_inicio DATE,
    periodo_fin DATE,
    estado_validacion TEXT DEFAULT 'pendiente_validar',
        -- 'validado' | 'pendiente_validar' | 'descuadrado' | 'pago_parcial'
    requiere_revision_propiedad BOOLEAN DEFAULT FALSE,
    id_transaccion_banco TEXT,                        -- bank's own ID (Workflow 1B dedup key)
    referencia_original TEXT,                         -- date_code_type_amount (Workflow 1C dedup key)
    origen_raw JSONB,
    importado_en TIMESTAMP DEFAULT now(),
    -- One dedup key per source. NULLs never conflict with each other in a UNIQUE constraint,
    -- so each source only collides with itself.
    CONSTRAINT uq_mov_rentila UNIQUE (propiedad_id, fecha, de_a, monto, tipo, descripcion),
    CONSTRAINT uq_mov_banco UNIQUE (id_transaccion_banco),
    CONSTRAINT uq_mov_registro UNIQUE (referencia_original)
);

CREATE TABLE regularizacion_bancaria (
    id SERIAL PRIMARY KEY,
    propiedad_id INTEGER REFERENCES propiedades(id),
    movimiento_relacionado_id INTEGER REFERENCES movimientos(id),
    fecha DATE NOT NULL,
    de_a TEXT,
    monto NUMERIC(10,2) NOT NULL,
    tipo TEXT,
    descripcion TEXT,
    referencia_pago TEXT,
    metodo_pago TEXT,
    origen_raw JSONB,
    importado_en TIMESTAMP DEFAULT now(),
    CONSTRAINT uq_reg UNIQUE (propiedad_id, fecha, de_a, monto, tipo, descripcion)
);

CREATE TABLE liquidaciones (
    id SERIAL PRIMARY KEY,
    propiedad_id INTEGER NOT NULL REFERENCES propiedades(id),
    mes DATE NOT NULL,                  -- first day of the settled month
    ingresos NUMERIC(10,2) NOT NULL DEFAULT 0,
    gastos NUMERIC(10,2) NOT NULL DEFAULT 0,
    honorarios_gestion NUMERIC(10,2) NOT NULL DEFAULT 0,
    iva NUMERIC(10,2) NOT NULL DEFAULT 0,
    rotaciones NUMERIC(10,2) NOT NULL DEFAULT 0,
    reparaciones NUMERIC(10,2) NOT NULL DEFAULT 0,
    neto_propietario NUMERIC(10,2) NOT NULL DEFAULT 0,
    estado TEXT DEFAULT 'pendiente',    -- 'validado' | 'pendiente' | 'factura_aparte'
    detalle_calculo JSONB,              -- full breakdown for audit
    datos_speedinvoice TEXT,            -- invoice data ready to copy
    creado_en TIMESTAMP DEFAULT now(),
    UNIQUE (propiedad_id, mes)          -- re-running a month updates, never duplicates
);

CREATE TABLE colaboradores (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE colaborador_servicios (
    id SERIAL PRIMARY KEY,
    colaborador_id INTEGER REFERENCES colaboradores(id),
    propiedad_id INTEGER REFERENCES propiedades(id),
    tipo_servicio TEXT NOT NULL,        -- captacion | incidencia | salida_completa | salida_habitacion | visita_adicional | servicio_adicional
    fecha DATE,
    horas NUMERIC(6,2),
    num_visitas INTEGER,
    formalizado BOOLEAN,
    repercutible_propietario BOOLEAN DEFAULT FALSE,
    importe_calculado NUMERIC(10,2)     -- NULL until Workflow 7 computes it
);

CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    workflow_origen TEXT,
    tipo_evento TEXT,                   -- info | error
    disparado_por TEXT,
    inicio TIMESTAMP,
    fin TIMESTAMP,
    duracion_ms INTEGER,
    propiedades_procesadas INTEGER,
    liquidaciones_generadas INTEGER,
    errores_detectados INTEGER,
    payload JSONB,
    creado_en TIMESTAMP DEFAULT now()
);

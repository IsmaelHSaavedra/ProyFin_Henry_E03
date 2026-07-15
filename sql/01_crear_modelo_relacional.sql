/*
    01_crear_modelo_relacional.sql
    Define llaves primarias y foráneas para construir el modelo relacional.

    Este script debe ejecutarse después de importar todas las tablas CSV
    dentro del esquema analytics.
*/

USE OlistAnalytics;


/* =========================================================
   1. LLAVES PRIMARIAS
   ========================================================= */

/* dim_productos */

ALTER TABLE analytics.dim_productos
ALTER COLUMN id_producto NVARCHAR(50) NOT NULL;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = 'analytics'
      AND TABLE_NAME = 'dim_productos'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
)
BEGIN
    ALTER TABLE analytics.dim_productos
    ADD CONSTRAINT pk_dim_productos
    PRIMARY KEY (id_producto);
END;


/* dim_clientes */

ALTER TABLE analytics.dim_clientes
ALTER COLUMN id_cliente_unico NVARCHAR(50) NOT NULL;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = 'analytics'
      AND TABLE_NAME = 'dim_clientes'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
)
BEGIN
    ALTER TABLE analytics.dim_clientes
    ADD CONSTRAINT pk_dim_clientes
    PRIMARY KEY (id_cliente_unico);
END;


/* fact_pedidos */

ALTER TABLE analytics.fact_pedidos
ALTER COLUMN id_pedido NVARCHAR(50) NOT NULL;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = 'analytics'
      AND TABLE_NAME = 'fact_pedidos'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
)
BEGIN
    ALTER TABLE analytics.fact_pedidos
    ADD CONSTRAINT pk_fact_pedidos
    PRIMARY KEY (id_pedido);
END;


/* fact_pagos */

ALTER TABLE analytics.fact_pagos
ALTER COLUMN id_pago NVARCHAR(100) NOT NULL;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = 'analytics'
      AND TABLE_NAME = 'fact_pagos'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
)
BEGIN
    ALTER TABLE analytics.fact_pagos
    ADD CONSTRAINT pk_fact_pagos
    PRIMARY KEY (id_pago);
END;


/* fact_interacciones */

ALTER TABLE analytics.fact_interacciones
ALTER COLUMN id_pedido NVARCHAR(50) NOT NULL;

ALTER TABLE analytics.fact_interacciones
ALTER COLUMN id_articulo_pedido INT NOT NULL;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = 'analytics'
      AND TABLE_NAME = 'fact_interacciones'
      AND CONSTRAINT_TYPE = 'PRIMARY KEY'
)
BEGIN
    ALTER TABLE analytics.fact_interacciones
    ADD CONSTRAINT pk_fact_interacciones
    PRIMARY KEY (id_pedido, id_articulo_pedido);
END;


/* =========================================================
   2. LLAVES FORÁNEAS
   ========================================================= */

/* dim_clientes 1 --- N fact_pedidos */

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'fk_fact_pedidos_dim_clientes'
)
BEGIN
    ALTER TABLE analytics.fact_pedidos
    ADD CONSTRAINT fk_fact_pedidos_dim_clientes
    FOREIGN KEY (id_cliente_unico)
    REFERENCES analytics.dim_clientes (id_cliente_unico);
END;


/* fact_pedidos 1 --- N fact_pagos */

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'fk_fact_pagos_fact_pedidos'
)
BEGIN
    ALTER TABLE analytics.fact_pagos
    ADD CONSTRAINT fk_fact_pagos_fact_pedidos
    FOREIGN KEY (id_pedido)
    REFERENCES analytics.fact_pedidos (id_pedido);
END;


/* fact_pedidos 1 --- N fact_interacciones */

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'fk_fact_interacciones_fact_pedidos'
)
BEGIN
    ALTER TABLE analytics.fact_interacciones
    ADD CONSTRAINT fk_fact_interacciones_fact_pedidos
    FOREIGN KEY (id_pedido)
    REFERENCES analytics.fact_pedidos (id_pedido);
END;


/* dim_productos 1 --- N fact_interacciones */

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'fk_fact_interacciones_dim_productos'
)
BEGIN
    ALTER TABLE analytics.fact_interacciones
    ADD CONSTRAINT fk_fact_interacciones_dim_productos
    FOREIGN KEY (id_producto)
    REFERENCES analytics.dim_productos (id_producto);
END;


/* dim_fechas 1 --- N fact_interacciones */

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'fk_fact_interacciones_dim_fechas'
)
BEGIN
    ALTER TABLE analytics.fact_interacciones
    ADD CONSTRAINT fk_fact_interacciones_dim_fechas
    FOREIGN KEY (id_fecha_compra)
    REFERENCES analytics.dim_fechas (id_fecha);
END;


/* dim_fechas 1 --- N fact_pedidos */

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'fk_fact_pedidos_dim_fechas'
)
BEGIN
    ALTER TABLE analytics.fact_pedidos
    ADD CONSTRAINT fk_fact_pedidos_dim_fechas
    FOREIGN KEY (id_fecha_compra)
    REFERENCES analytics.dim_fechas (id_fecha);
END;

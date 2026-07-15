/*
    02_validaciones.sql
    Comprueba conteos, unicidad, nulos, integridad referencial
    y funcionamiento general del modelo relacional.
*/

USE OlistAnalytics;


/* =========================================================
   1. CONTEO DE FILAS POR TABLA
   ========================================================= */

SELECT COUNT(*) AS total_filas
FROM analytics.dim_fechas;

SELECT COUNT(*) AS total_filas
FROM analytics.dim_productos;

SELECT COUNT(*) AS total_filas
FROM analytics.dim_clientes;

SELECT COUNT(*) AS total_filas
FROM analytics.fact_interacciones;

SELECT COUNT(*) AS total_filas
FROM analytics.fact_pedidos;

SELECT COUNT(*) AS total_filas
FROM analytics.fact_pagos;


/* =========================================================
   2. VALIDACIÓN DE LLAVES PRIMARIAS
   ========================================================= */

/* dim_productos */

SELECT
    COUNT(*) AS total_filas,
    COUNT(id_producto) AS ids_no_nulos,
    COUNT(DISTINCT id_producto) AS ids_unicos
FROM analytics.dim_productos;


/* dim_clientes */

SELECT
    COUNT(*) AS total_filas,
    COUNT(id_cliente_unico) AS ids_no_nulos,
    COUNT(DISTINCT id_cliente_unico) AS ids_unicos
FROM analytics.dim_clientes;


/* fact_pedidos */

SELECT
    COUNT(*) AS total_filas,
    COUNT(id_pedido) AS ids_no_nulos,
    COUNT(DISTINCT id_pedido) AS ids_unicos
FROM analytics.fact_pedidos;


/* fact_pagos */

SELECT
    COUNT(*) AS total_filas,
    COUNT(id_pago) AS ids_no_nulos,
    COUNT(DISTINCT id_pago) AS ids_unicos
FROM analytics.fact_pagos;


/* fact_interacciones: llave primaria compuesta */

SELECT COUNT(*) AS combinaciones_duplicadas
FROM (
    SELECT
        id_pedido,
        id_articulo_pedido
    FROM analytics.fact_interacciones
    GROUP BY
        id_pedido,
        id_articulo_pedido
    HAVING COUNT(*) > 1
) AS duplicados;


/* =========================================================
   3. REVISIÓN DE RESTRICCIONES
   ========================================================= */

SELECT
    tc.TABLE_SCHEMA AS esquema,
    tc.TABLE_NAME AS tabla,
    tc.CONSTRAINT_NAME AS restriccion,
    tc.CONSTRAINT_TYPE AS tipo
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
WHERE tc.TABLE_SCHEMA = 'analytics'
ORDER BY
    tc.TABLE_NAME,
    tc.CONSTRAINT_TYPE;


/* =========================================================
   4. VALIDACIÓN DE INTEGRIDAD REFERENCIAL
   ========================================================= */

SELECT COUNT(*) AS clientes_sin_dimension
FROM analytics.fact_pedidos AS p
LEFT JOIN analytics.dim_clientes AS c
    ON p.id_cliente_unico = c.id_cliente_unico
WHERE c.id_cliente_unico IS NULL;


SELECT COUNT(*) AS pagos_sin_pedido
FROM analytics.fact_pagos AS pg
LEFT JOIN analytics.fact_pedidos AS p
    ON pg.id_pedido = p.id_pedido
WHERE p.id_pedido IS NULL;


SELECT COUNT(*) AS interacciones_sin_pedido
FROM analytics.fact_interacciones AS i
LEFT JOIN analytics.fact_pedidos AS p
    ON i.id_pedido = p.id_pedido
WHERE p.id_pedido IS NULL;


SELECT COUNT(*) AS interacciones_sin_producto
FROM analytics.fact_interacciones AS i
LEFT JOIN analytics.dim_productos AS p
    ON i.id_producto = p.id_producto
WHERE p.id_producto IS NULL;


SELECT COUNT(*) AS interacciones_sin_fecha
FROM analytics.fact_interacciones AS i
LEFT JOIN analytics.dim_fechas AS f
    ON i.id_fecha_compra = f.id_fecha
WHERE f.id_fecha IS NULL;


SELECT COUNT(*) AS pedidos_sin_fecha
FROM analytics.fact_pedidos AS p
LEFT JOIN analytics.dim_fechas AS f
    ON p.id_fecha_compra = f.id_fecha
WHERE f.id_fecha IS NULL;


/* =========================================================
   5. PRUEBA FINAL DEL MODELO RELACIONAL
   ========================================================= */

SELECT TOP 10
    p.id_pedido,
    c.estado_cliente,
    f.fecha,
    p.ticket_total
FROM analytics.fact_pedidos AS p
LEFT JOIN analytics.dim_clientes AS c
    ON p.id_cliente_unico = c.id_cliente_unico
LEFT JOIN analytics.dim_fechas AS f
    ON p.id_fecha_compra = f.id_fecha
ORDER BY p.ticket_total DESC;

/*
    03_consultas_analiticas.sql
    Consultas base para análisis SQL y construcción del dashboard en Power BI.
*/

USE OlistAnalytics;


/* =========================================================
   1. PRINCIPALES KPI
   ========================================================= */

SELECT
    COUNT(*) AS total_pedidos,
    COUNT(DISTINCT id_cliente_unico) AS clientes_unicos,
    SUM(ticket_total) AS valor_total,
    AVG(ticket_total) AS ticket_promedio,
    AVG(CAST(cantidad_articulos AS DECIMAL(10,2))) AS articulos_promedio,
    SUM(pedido_multiproducto) * 100.0 / COUNT(*) AS porcentaje_multiproducto,
    SUM(pedido_multicategoria) * 100.0 / COUNT(*) AS porcentaje_multicategoria
FROM analytics.fact_pedidos;


/* =========================================================
   2. TENDENCIA MENSUAL
   ========================================================= */

SELECT
    anio_mes_compra,
    COUNT(*) AS total_pedidos,
    SUM(ticket_total) AS valor_total,
    AVG(ticket_total) AS ticket_promedio,
    AVG(CAST(cantidad_articulos AS DECIMAL(10,2))) AS articulos_promedio
FROM analytics.fact_pedidos
GROUP BY anio_mes_compra
ORDER BY anio_mes_compra;


/* =========================================================
   3. RENDIMIENTO DE CATEGORÍAS
   ========================================================= */

SELECT
    i.categoria_producto,
    COUNT(DISTINCT i.id_pedido) AS total_pedidos,
    COUNT(DISTINCT i.id_cliente_unico) AS clientes_unicos,
    SUM(i.valor_articulo) AS valor_total,
    AVG(i.valor_articulo) AS valor_promedio_articulo,
    SUM(i.interaccion) AS unidades_vendidas
FROM analytics.fact_interacciones AS i
GROUP BY i.categoria_producto
ORDER BY valor_total DESC;


/* =========================================================
   4. SEGMENTACIÓN DE CLIENTES
   ========================================================= */

SELECT
    CASE
        WHEN cantidad_pedidos = 1 THEN 'cliente_nuevo'
        WHEN cantidad_pedidos BETWEEN 2 AND 3 THEN 'cliente_recurrente'
        ELSE 'cliente_frecuente'
    END AS segmento_cliente,
    COUNT(*) AS total_clientes,
    AVG(CAST(cantidad_pedidos AS DECIMAL(10,2))) AS pedidos_promedio,
    AVG(CAST(productos_unicos AS DECIMAL(10,2))) AS productos_unicos_promedio
FROM analytics.dim_clientes
GROUP BY
    CASE
        WHEN cantidad_pedidos = 1 THEN 'cliente_nuevo'
        WHEN cantidad_pedidos BETWEEN 2 AND 3 THEN 'cliente_recurrente'
        ELSE 'cliente_frecuente'
    END
ORDER BY total_clientes DESC;


/* =========================================================
   5. MÉTODOS DE PAGO
   ========================================================= */

SELECT
    tipo_pago,
    COUNT(*) AS total_pagos,
    COUNT(DISTINCT id_pedido) AS pedidos_asociados,
    SUM(valor_pago) AS valor_pagado,
    AVG(valor_pago) AS pago_promedio,
    AVG(CAST(cuotas_pago AS DECIMAL(10,2))) AS cuotas_promedio
FROM analytics.fact_pagos
GROUP BY tipo_pago
ORDER BY valor_pagado DESC;


/* =========================================================
   6. COMPOSICIÓN DE CANASTAS
   ========================================================= */

SELECT
    tipo_canasta,
    COUNT(*) AS total_pedidos,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS porcentaje_pedidos,
    AVG(ticket_total) AS ticket_promedio,
    AVG(CAST(cantidad_articulos AS DECIMAL(10,2))) AS articulos_promedio
FROM analytics.fact_pedidos
GROUP BY tipo_canasta
ORDER BY total_pedidos DESC;


/* =========================================================
   7. RENDIMIENTO POR ESTADO
   ========================================================= */

SELECT
    estado_cliente,
    COUNT(*) AS total_pedidos,
    COUNT(DISTINCT id_cliente_unico) AS clientes_unicos,
    SUM(ticket_total) AS valor_total,
    AVG(ticket_total) AS ticket_promedio
FROM analytics.fact_pedidos
GROUP BY estado_cliente
ORDER BY valor_total DESC;

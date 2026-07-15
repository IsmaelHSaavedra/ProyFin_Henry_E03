/*
 Comenzamos por crear la base de datos para el negocio Olist
 */

use master;
if db_id('OlistAnalytics') is null
begin
	create database OlistAnalytics;
end;

/*
 Confirmamos que la creación fue exitosa
 */

select name
from sys.databases
where name = 'OlistAnalytics';

/*
 Creamos el schema donde vamos a trabajar
 */

use OlistAnalytics;
if not exists (
	select 1
	from sys.schemas
	where name = 'analytics'
)
begin
	exec('CREATE SCHEMA analytics');
end;

/*
 Confirmamos que fue creado con éxito
 */

select name
from sys.schemas
where name = 'analytics';

/* 
Como el schema y las tablas no son visibles sin contenido
creamos una tabla dim_fechas para luego importar los datos que obtuvimos desde el ETL
*/ 

USE OlistAnalytics;
CREATE TABLE analytics.dim_fechas (
    id_fecha INT NOT NULL,
    fecha DATE NOT NULL,
    anio SMALLINT NOT NULL,
    trimestre TINYINT NOT NULL,
    mes TINYINT NOT NULL,
    nombre_mes VARCHAR(15) NOT NULL,
    dia TINYINT NOT NULL,
    dia_semana TINYINT NOT NULL,
    nombre_dia VARCHAR(15) NOT NULL,
    anio_mes CHAR(7) NOT NULL,
    CONSTRAINT pk_dim_fechas PRIMARY KEY (id_fecha)
);

/*
 Posteriormente importamos manualmente todas las tablas dimensionales y de hechos y
 corroboramos que todas las tablas y su contenido se hayan importado correctamente 
 */

SELECT 'dim_fechas' AS tabla, COUNT(*) AS filas
FROM analytics.dim_fechas

SELECT 'dim_productos', COUNT(*)	
FROM analytics.dim_productos

SELECT 'dim_clientes', COUNT(*)
FROM analytics.dim_clientes

SELECT 'fact_interacciones', COUNT(*)
FROM analytics.fact_interacciones

SELECT 'fact_pedidos', COUNT(*)
FROM analytics.fact_pedidos

SELECT 'fact_pagos', COUNT(*)
FROM analytics.fact_pagos;


/*
 Realizamos las consultas base
 */


/*
 * PRINCIPALES KPI's
 */
select
	count(*) as total_pedidos,
	count(distinct id_cliente_unico) as clientes_unicos,
	sum(ticket_total) as valor_total,
	avg(ticket_total) as ticket_promedio,
	avg(cast(cantidad_articulos as decimal (10,2))) as articulos_promedio,
	sum(pedido_multiproducto) * 100.0 / count(*) as porcentaje_multiproducto,
	sum(pedido_multicategoria) * 100.0 / count(*) as procentaje_multicategoria
from analytics.fact_pedidos;

/*
 * TENDENCIA MENSUAL
 */

select
	anio_mes_compra,
	count(*) as total_pedidos,
	sum(ticket_total) as valor_total,
	avg(ticket_total) as ticket_promedio,
	avg(cast(cantidad_articulos as decimal (10,2))) as articulos_promedio
from analytics.fact_pedidos
group by anio_mes_compra
order by anio_mes_compra;

/*
 * RENDIMIENTO DE CATEGORÍAS 
 */

select
	i.categoria_producto,
	count(distinct i.id_pedido) as total_pedidos,
	count(distinct i.id_cliente_unico) as clientes_unicos,
	sum(i.valor_articulo) as valor_total,
	avg(i.valor_articulo) as valor_promedio_articulo,
	sum(i.interaccion) as unidades_vendidas
from analytics.fact_interacciones as i
group by i.categoria_producto
order by valor_total desc;

/*
 * SEGMENTACION DE CLIENTES 
 */

select
	case 
		when cantidad_pedidos = 1 then 'cliente_nuevo'
		when cantidad_pedidos between 2 and 3 then 'cliente_recurrente'
		else 'cliente_frecuente'
	end as segmento_cliente,
	count(*) as total_clientes,
	avg(cast(cantidad_pedidos as decimal (10,2))) as pedidos_promedio,
	avg(cast(productos_unicos as decimal (10,2))) as productos_unicos_promedio
from analytics.dim_clientes
group by
	case
		when cantidad_pedidos = 1 then 'cliente_nuevo'
		when cantidad_pedidos between 2 and 3 then 'cliente_recurrente'
		else 'cliente_frecuente'
	end
order by total_clientes desc;

/*
 * MÉTODOS DE PAGO 
 */

select
	tipo_pago,
	count(*) as total_pagos,
	count(distinct id_pedido) as pedidos_asociados,
	sum(valor_pago) as valor_pagado,
	avg(valor_pago) as pago_promedio,
	avg(cast(cuotas_pago as decimal(10,2))) as cuotas_promedio
from analytics.fact_pagos
group by tipo_pago
order by valor_pagado desc;

/*
 * COMPOSICIÓN DE CANASTAS
 */

select
	tipo_canasta,
	count(*) as total_pedidos,
	count(*) * 100.0 / sum(count(*)) over() as porcentaje_pedidos,
	avg(ticket_total) as ticket_promedio,
	avg(cast(cantidad_articulos as decimal(10,2))) articulos_promedio
from analytics.fact_pedidos
group by tipo_canasta
order by total_pedidos desc;

/*
 * RENDIMIENTO POR ESTADO
 */

SELECT
    estado_cliente,
    COUNT(*) AS total_pedidos,
    COUNT(DISTINCT id_cliente_unico) AS clientes_unicos,
    SUM(ticket_total) AS valor_total,
    AVG(ticket_total) AS ticket_promedio
FROM analytics.fact_pedidos
GROUP BY estado_cliente
ORDER BY valor_total DESC;


/*
 Una vez terminamos de hacer las consultas necesarias para el análisis
 vamos a establecer las relaciones entre las tablas
 */

/

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

/*
 Queremos validar que id_producto sea único y no tenga nulos para que cumpla como key
 */

/*
 * 1. VERIFICAR REQUISITOS PARA PK
 */
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

/*
 * 2. VERICAR TIPO DE DATO
 */
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'analytics'
  AND TABLE_NAME = 'fact_interacciones'
  AND COLUMN_NAME IN (
      'id_pedido',
      'id_articulo_pedido'
  );

/*
 * 3. TRANSFORMADOR DE TIPO DE DATO
 */
ALTER TABLE analytics.fact_interacciones
ALTER COLUMN id_pedido NVARCHAR(50) NOT NULL;

ALTER TABLE analytics.fact_interacciones
ALTER COLUMN id_articulo_pedido INT NOT NULL;

/*
 * 4. CREACIÓN DE PK
 */

ALTER TABLE analytics.fact_interacciones
ADD CONSTRAINT pk_fact_interacciones
PRIMARY KEY (id_pedido, id_articulo_pedido);


/*
 * Una vez creadas todas las llaves primarias en las tablas
 * validamos que todos los datos tienen dimensión en las demás tablas
 */	

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

/*
 * Por último, creamos las llaves foráneas
 */
 
 ALTER TABLE analytics.fact_pedidos
ADD CONSTRAINT fk_fact_pedidos_dim_clientes
FOREIGN KEY (id_cliente_unico)
REFERENCES analytics.dim_clientes (id_cliente_unico);


ALTER TABLE analytics.fact_pagos
ADD CONSTRAINT fk_fact_pagos_fact_pedidos
FOREIGN KEY (id_pedido)
REFERENCES analytics.fact_pedidos (id_pedido);


ALTER TABLE analytics.fact_interacciones
ADD CONSTRAINT fk_fact_interacciones_fact_pedidos
FOREIGN KEY (id_pedido)
REFERENCES analytics.fact_pedidos (id_pedido);


ALTER TABLE analytics.fact_interacciones
ADD CONSTRAINT fk_fact_interacciones_dim_productos
FOREIGN KEY (id_producto)
REFERENCES analytics.dim_productos (id_producto);


ALTER TABLE analytics.fact_interacciones
ADD CONSTRAINT fk_fact_interacciones_dim_fechas
FOREIGN KEY (id_fecha_compra)
REFERENCES analytics.dim_fechas (id_fecha);


ALTER TABLE analytics.fact_pedidos
ADD CONSTRAINT fk_fact_pedidos_dim_fechas
FOREIGN KEY (id_fecha_compra)
REFERENCES analytics.dim_fechas (id_fecha);



/*
 * Verificamos que el modelo relacional funciona correctamente
 */

select top 10
    p.id_pedido,
    c.estado_cliente,
    f.fecha,
    p.ticket_total
from analytics.fact_pedidos p
left join analytics.dim_clientes c
    on p.id_cliente_unico = c.id_cliente_unico
left join analytics.dim_fechas f
    on p.id_fecha_compra = f.id_fecha
order by p.ticket_total desc;

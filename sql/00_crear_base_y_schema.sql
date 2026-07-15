/*  Comenzamos por crear la base de datos OlistAnalytics, el esquema analytics
    y la tabla dim_fechas, utilizada como punto inicial para importar
    posteriormente las tablas procesadas desde el ETL. 
*/

USE master;

IF DB_ID('OlistAnalytics') IS NULL
BEGIN
    CREATE DATABASE OlistAnalytics;
END;

SELECT name
FROM sys.databases
WHERE name = 'OlistAnalytics';


USE OlistAnalytics;

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analytics'
)
BEGIN
    EXEC('CREATE SCHEMA analytics');
END;

SELECT name
FROM sys.schemas
WHERE name = 'analytics';


/*
    La tabla dim_fechas se crea manualmente para que el esquema analytics
    sea visible en DBeaver y para importar después dim_fechas.csv.
*/

IF OBJECT_ID('analytics.dim_fechas', 'U') IS NULL
BEGIN
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
END;

/*
    Después de ejecutar este archivo se importan manualmente desde DBeaver:

    - dim_fechas.csv
    - dim_productos.csv
    - dim_clientes.csv
    - fact_interacciones.csv
    - fact_pedidos.csv
    - fact_pagos.csv

    Todas deben cargarse dentro del esquema analytics.
*/

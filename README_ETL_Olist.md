# ETL Olist para recomendador y negocio

Este paquete genera tablas limpias para análisis de ventas, ticket promedio, regiones, clientes y afinidad producto-producto/categoría-categoría.

## Archivo principal

- `ETL_recomendador_Olist.ipynb`: notebook ejecutable del ETL.
- `etl_recomendador_olist.py`: versión script del mismo flujo.

## Salidas principales

- `fact_orders.csv`: una fila por orden. Sirve para ticket promedio, temporalidad, métodos de pago y clientes.
- `fact_order_items.csv`: una fila por producto dentro de una orden. Sirve para ventas por producto, categoría, seller y región.
- `dim_customers.csv`: clientes únicos con frecuencia, ubicación y recurrencia.
- `dim_products.csv`: productos únicos con categoría, dimensiones y métricas de venta.
- `dim_sellers.csv`: vendedores únicos.
- `dim_dates.csv`: calendario analítico.
- `mart_sales_by_product.csv`: productos más vendidos e ingresos.
- `mart_sales_by_region_product.csv`: productos más vendidos por región/estado.
- `mart_sales_by_gender_product.csv`: preparado para género, pero el dataset actual no lo trae.
- `mart_sales_by_season.csv`: ventas y ticket por mes/temporada.
- `mart_category_affinity.csv`: categorías que suelen aparecer juntas.
- `mart_product_affinity.csv`: productos que suelen aparecer juntos.
- `mart_recommendation_candidates.csv`: candidatos directos para recomendador por producto ancla.
- `data_quality_report.csv`: calidad de columnas.
- `validation_summary.csv`: validaciones básicas del ETL.

## Nota sobre género

El dataset público de Olist no contiene género del cliente. El campo `customer_gender` queda como `unknown` para dejar listo el pipeline si más adelante se integra una fuente externa de perfiles, encuesta o CRM.

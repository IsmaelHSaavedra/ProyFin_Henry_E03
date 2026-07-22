"""
pipeline.py
===========
Pipeline end-to-end del Sistema de Recomendación.
Ejecuta el flujo completo: Extract -> Transform -> Model.

Uso:
    python src/pipeline.py

Proyecto: Datalab - Sistema de Recomendación - Equipo datalab
Integrantes: Luis Crespo (Data Engineer)
Alejandro Zarzosa (Data Scientist)
"""

from extract import cargar_datos
from transform import ejecutar_etl
from model import preparar_productos, recomendar_coseno


def main():
    """
    Ejecuta el pipeline completo de principio a fin.
    """
    print("=" * 60)
    print("PIPELINE - SISTEMA DE RECOMENDACIÓN DATALAB")
    print("=" * 60)

    # 1. EXTRACT: cargar datos crudos
    ruta_datos = "Brazilian E-Commerce Public Dataset by Olist.csv"
    df = cargar_datos(ruta_datos)

    # 2. TRANSFORM: limpieza + features
    df = ejecutar_etl(df, ruta_salida="olist_limpio.csv")

    # 3. MODEL: preparar modelos
    product_sample, cosine_matrix, euclidean_matrix = preparar_productos(df)

    # 4. DEMO: generar una recomendación de ejemplo
    print("\n" + "=" * 60)
    print("EJEMPLO DE RECOMENDACIÓN")
    print("=" * 60)
    producto_ejemplo = product_sample.iloc[0]
    print(f"Producto base: {producto_ejemplo['product_category_name']} - ${producto_ejemplo['price']:.2f}")
    print("\nRecomendaciones (modelo Coseno):\n")
    recomendaciones = recomendar_coseno(
        producto_ejemplo['product_id'],
        product_sample,
        cosine_matrix
    )
    print(recomendaciones.to_string(index=False))

    print("\n" + "=" * 60)
    print("PIPELINE COMPLETADO EXITOSAMENTE")
    print("=" * 60)


if __name__ == "__main__":
    main()
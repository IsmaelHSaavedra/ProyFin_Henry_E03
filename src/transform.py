"""
transform.py
============
Módulo de transformación de datos (ETL).
Limpia el dataset y crea las features de ingeniería de características.

Proyecto: Datalab - Sistema de Recomendación - Equipo datalab
Integrantes: Luis Crespo (Data Engineer)
Alejandro Zarzosa (Data Scientist)
"""

import pandas as pd


def limpiar_datos(df: pd.DataFrame) -> pd.DataFrame:
    """
    Aplica la limpieza del dataset.

    Pasos:
    - Filtra solo pedidos entregados
    - Elimina duplicados
    - Convierte columnas de fecha a datetime
    - Elimina columnas irrelevantes

    Args:
        df (pd.DataFrame): DataFrame crudo.

    Returns:
        pd.DataFrame: DataFrame limpio.
    """
    print("[TRANSFORM] Iniciando limpieza de datos...")
    df = df.copy()

    # Filtrar solo pedidos entregados (si existe la columna)
    if 'order_status' in df.columns:
        df = df[df['order_status'] == 'delivered']

    # Eliminar duplicados
    filas_antes = len(df)
    df = df.drop_duplicates()
    print(f"[TRANSFORM] Duplicados eliminados: {filas_antes - len(df):,}")

    # Convertir fechas
    if 'order_purchase_timestamp' in df.columns:
        df['order_purchase_timestamp'] = pd.to_datetime(
            df['order_purchase_timestamp'], errors='coerce'
        )

    # Eliminar columna índice residual si existe
    if 'Unnamed: 0' in df.columns:
        df = df.drop(columns=['Unnamed: 0'])

    print(f"[TRANSFORM] Limpieza completada: {df.shape[0]:,} filas")
    return df


def crear_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Crea las features de ingeniería de características.

    Features creadas:
    - volumen_producto: largo x alto x ancho
    - anio_compra: año de la fecha de compra
    - mes_compra: mes de la fecha de compra

    Args:
        df (pd.DataFrame): DataFrame limpio.

    Returns:
        pd.DataFrame: DataFrame con las nuevas features.
    """
    print("[TRANSFORM] Creando features de ingeniería...")
    df = df.copy()

    # Feature 1: Volumen del producto
    if all(c in df.columns for c in ['product_length_cm', 'product_height_cm', 'product_width_cm']):
        df['volumen_producto'] = (
            df['product_length_cm'] *
            df['product_height_cm'] *
            df['product_width_cm']
        )

    # Features temporales
    if 'order_purchase_timestamp' in df.columns:
        df['anio_compra'] = df['order_purchase_timestamp'].dt.year
        df['mes_compra'] = df['order_purchase_timestamp'].dt.month

    print("[TRANSFORM] Features creadas: volumen_producto, anio_compra, mes_compra")
    return df


def ejecutar_etl(df: pd.DataFrame, ruta_salida: str = "olist_limpio.csv") -> pd.DataFrame:
    """
    Ejecuta el proceso ETL completo: limpieza + features + guardado.

    Args:
        df (pd.DataFrame): DataFrame crudo.
        ruta_salida (str): Ruta donde guardar el dataset limpio.

    Returns:
        pd.DataFrame: DataFrame procesado.
    """
    df = limpiar_datos(df)
    df = crear_features(df)
    df.to_csv(ruta_salida, index=False)
    print(f"[TRANSFORM] Dataset limpio guardado en: {ruta_salida}")
    return df
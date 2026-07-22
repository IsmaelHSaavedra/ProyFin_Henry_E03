"""
extract.py
==========
Módulo de extracción de datos.
Carga el dataset crudo de Olist desde la ruta especificada.

Proyecto: Datalab - Sistema de Recomendación - Equipo datalab
Integrantes: Luis Crespo (Data Engineer)
Alejandro Zarzosa (Data Scientist)
"""

import pandas as pd


def cargar_datos(ruta: str) -> pd.DataFrame:
    """
    Carga el dataset crudo de Olist.

    Args:
        ruta (str): Ruta al archivo CSV de datos crudos.

    Returns:
        pd.DataFrame: DataFrame con los datos cargados.
    """
    print("[EXTRACT] Cargando dataset crudo...")
    df = pd.read_csv(ruta)
    print(f"[EXTRACT] Datos cargados: {df.shape[0]:,} filas x {df.shape[1]} columnas")
    return df
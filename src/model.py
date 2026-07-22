"""
model.py
========
Módulo de modelado del sistema de recomendación.
Implementa y compara 3 enfoques: Popularidad, Coseno y Euclidiana.

Proyecto: Datalab - Sistema de Recomendación - Equipo datalab
Integrantes: Luis Crespo (Data Engineer)
Alejandro Zarzosa (Data Scientist)
"""

import pandas as pd
from sklearn.preprocessing import LabelEncoder, MinMaxScaler
from sklearn.metrics.pairwise import cosine_similarity, euclidean_distances


def preparar_productos(df: pd.DataFrame, sample_size: int = 5000):
    """
    Prepara la tabla de productos únicos y las matrices de similitud.

    Args:
        df (pd.DataFrame): Dataset limpio.
        sample_size (int): Tamaño de la muestra de productos.

    Returns:
        tuple: (product_sample, cosine_matrix, euclidean_matrix)
    """
    print("[MODEL] Preparando datos para modelado...")
    df = df.copy()

    # Codificar categoría
    le = LabelEncoder()
    df['category_encoded'] = le.fit_transform(df['product_category_name'].astype(str))

    # Agregar por producto único
    product_features = df.groupby('product_id').agg({
        'price': 'mean',
        'product_weight_g': 'mean',
        'volumen_producto': 'mean',
        'category_encoded': 'first',
        'product_category_name': 'first'
    }).reset_index()

    print(f"[MODEL] Productos únicos: {len(product_features):,}")

    # Muestra para no exceder memoria
    product_sample = product_features.sample(
        min(sample_size, len(product_features)), random_state=42
    ).reset_index(drop=True)
    print(f"[MODEL] Muestra utilizada: {len(product_sample):,} productos")

    # Normalizar features
    feature_columns = ['price', 'product_weight_g', 'volumen_producto', 'category_encoded']
    X = product_sample[feature_columns].fillna(0)
    scaler = MinMaxScaler()
    X_scaled = scaler.fit_transform(X)

    # Matrices de similitud
    cosine_matrix = cosine_similarity(X_scaled)
    euclidean_matrix = euclidean_distances(X_scaled)
    print("[MODEL] Matrices de similitud calculadas")

    return product_sample, cosine_matrix, euclidean_matrix


def recomendar_coseno(product_id, product_sample, similarity_matrix, top_n=5):
    """
    Recomienda productos usando similitud coseno (modelo elegido).

    Args:
        product_id (str): ID del producto base.
        product_sample (pd.DataFrame): Muestra de productos.
        similarity_matrix (ndarray): Matriz de similitud coseno.
        top_n (int): Cantidad de recomendaciones.

    Returns:
        pd.DataFrame: Recomendaciones con su score de similitud.
    """
    idx = product_sample[product_sample['product_id'] == product_id].index[0]
    sim_scores = list(enumerate(similarity_matrix[idx]))
    sim_scores = sorted(sim_scores, key=lambda x: x[1], reverse=True)
    sim_scores = [s for s in sim_scores if s[0] != idx][:top_n]

    indices = [s[0] for s in sim_scores]
    scores = [s[1] for s in sim_scores]

    recomendaciones = product_sample.iloc[indices][
        ['product_id', 'product_category_name', 'price']
    ].copy()
    recomendaciones['similarity_score'] = scores
    return recomendaciones
"""
app.py
======
Despliegue del Sistema de Recomendacion - Equipo Datalab
Aplicacion interactiva con Streamlit.

Uso:
    streamlit run app.py

Proyecto: Datalab - Sistema de Recomendacion
Integrantes:
    - Luis Crespo (Data Engineer)
    - Alejandro Zarzosa (Data Scientist)
"""

import os
import streamlit as st
import pandas as pd
from sklearn.preprocessing import LabelEncoder, MinMaxScaler
from sklearn.metrics.pairwise import cosine_similarity, euclidean_distances


# ============================================================
# CONFIGURACION DE LA PAGINA
# ============================================================
st.set_page_config(
    page_title="Sistema de Recomendacion - Datalab",
    layout="wide"
)

# ============================================================
# TRADUCCION DE CATEGORIAS (portugues -> ingles)
# ============================================================
CATEGORIAS_EN = {
    "cool_stuff": "cool stuff",
    "brinquedos": "toys",
    "pet_shop": "pet shop",
    "moveis_decoracao": "furniture & decor",
    "cama_mesa_banho": "bed, bath & table",
    "perfumaria": "perfumery",
    "informatica_acessorios": "computer accessories",
    "utilidades_domesticas": "housewares",
    "papelaria": "stationery",
    "ferramentas_jardim": "garden tools",
    "esporte_lazer": "sports & leisure",
    "telefonia": "telephony",
    "audio": "audio",
    "beleza_saude": "health & beauty",
    "relogios_presentes": "watches & gifts",
    "bebes": "baby",
    "livros_tecnicos": "technical books",
    "dvds_blu_ray": "dvds & blu-ray",
    "consoles_games": "consoles & games",
    "alimentos": "food",
    "fashion_bolsas_e_acessorios": "fashion bags & accessories",
    "casa_conforto": "home comfort",
    "moveis_sala": "living room furniture",
    "instrumentos_musicais": "musical instruments",
    "automotivo": "automotive",
    "moveis_escritorio": "office furniture",
    "casa_construcao": "home construction",
    "eletronicos": "electronics",
    "sinalizacao_e_seguranca": "signaling & security",
    "cine_foto": "cinema & photo",
    "telefonia_fixa": "landline telephony",
    "fraldas_higiene": "diapers & hygiene",
    "pc_gamer": "gaming pc",
    "fashion_roupa_masculina": "men's fashion",
    "eletroportateis": "small appliances",
    "industria_comercio_e_negocios": "industry & business",
    "fashion_esporte": "sports fashion",
    "malas_acessorios": "luggage & accessories",
    "market_place": "marketplace",
    "eletrodomesticos": "home appliances",
    "agro_industria_e_comercio": "agribusiness",
    "climatizacao": "air conditioning",
    "artes": "arts",
    "la_cuisine": "cuisine",
    "livros_interesse_geral": "general interest books",
    "eletrodomesticos_2": "home appliances 2",
    "alimentos_bebidas": "food & drinks",
    "musica": "music",
    "moveis_quarto": "bedroom furniture",
    "fashion_calcados": "footwear fashion",
    "bebidas": "drinks",
    "artigos_de_natal": "christmas articles",
    "artigos_de_festas": "party articles",
    "moveis_colchao_e_estofado": "mattresses & upholstery",
    "cds_dvds_musicais": "music cds & dvds",
    "seguros_e_servicos": "insurance & services",
    "fashion_roupa_infanto_juvenil": "kids fashion",
    "fashion_roupa_feminina": "women's fashion",
    "pcs": "computers",
    "fashion_underwear_e_moda_praia": "underwear & beachwear",
    "livros_importados": "imported books",
    "artes_e_artesanato": "arts & crafts",
    "flores": "flowers",
    "construcao_ferramentas_jardim": "construction & garden tools",
    "construcao_ferramentas_iluminacao": "construction & lighting tools",
    "construcao_ferramentas_construcao": "construction tools",
    "construcao_ferramentas_seguranca": "construction safety tools",
    "construcao_ferramentas_ferramentas": "construction hand tools",
    "tablets_impressao_imagem": "tablets & printing",
    "portateis_casa_forno_e_cafe": "portable oven & coffee",
    "moveis_cozinha_area_de_servico_jantar_e_jardim": "kitchen & dining furniture",
    "portateis_cozinha_e_preparadores_de_alimentos": "portable kitchen appliances",
    "casa_conforto_2": "home comfort 2",
}


def traducir(categoria: str) -> str:
    """Traduce el nombre de la categoria de portugues a ingles."""
    return CATEGORIAS_EN.get(categoria, categoria)


# ============================================================
# CARGA Y PREPARACION DE DATOS
# ============================================================
@st.cache_data
def cargar_y_preparar_datos():
    """
    Carga el dataset limpio y prepara la tabla de productos unicos.
    Usa cache para no recalcular en cada interaccion del usuario.
    """
    df = pd.read_csv("olist_limpio.csv")

    le = LabelEncoder()
    df['category_encoded'] = le.fit_transform(df['product_category_name'].astype(str))

    product_features = df.groupby('product_id').agg({
        'price': 'mean',
        'product_weight_g': 'mean',
        'volumen_producto': 'mean',
        'category_encoded': 'first',
        'product_category_name': 'first'
    }).reset_index()

    product_sample = product_features.sample(
        5000, random_state=42
    ).reset_index(drop=True)

    # Columna con la categoria traducida para mostrar en pantalla
    product_sample['categoria_en'] = product_sample['product_category_name'].apply(traducir)

    return df, product_sample


def calcular_matriz(product_sample, peso_precio, peso_categoria, modelo):
    """
    Calcula la matriz de similitud o distancia segun el modelo elegido,
    aplicando los pesos definidos por el usuario.

    Args:
        product_sample: DataFrame de productos unicos
        peso_precio: peso del precio (0-100)
        peso_categoria: peso de la categoria (0-100)
        modelo: "Coseno" o "Euclidiana"

    Returns:
        Matriz de similitud (coseno) o de distancia (euclidiana)
    """
    feature_columns = ['price', 'product_weight_g', 'volumen_producto', 'category_encoded']
    X = product_sample[feature_columns].fillna(0)

    scaler = MinMaxScaler()
    X_scaled = pd.DataFrame(scaler.fit_transform(X), columns=feature_columns)

    # Aplicar pesos definidos por el usuario
    X_scaled['price'] = X_scaled['price'] * (peso_precio / 100)
    X_scaled['category_encoded'] = X_scaled['category_encoded'] * (peso_categoria / 100)

    if modelo == "Coseno":
        return cosine_similarity(X_scaled)
    return euclidean_distances(X_scaled)


def recomendar(product_id, product_sample, matriz, modelo, top_n=5):
    """
    Genera recomendaciones para un producto dado.

    Con coseno se ordena de mayor a menor (mas similitud es mejor).
    Con euclidiana se ordena de menor a mayor (menos distancia es mejor).
    """
    idx = product_sample[product_sample['product_id'] == product_id].index[0]
    scores = list(enumerate(matriz[idx]))

    if modelo == "Coseno":
        scores = sorted(scores, key=lambda x: x[1], reverse=True)
    else:
        scores = sorted(scores, key=lambda x: x[1])

    scores = [s for s in scores if s[0] != idx][:top_n]

    indices = [s[0] for s in scores]
    valores = [s[1] for s in scores]

    recomendaciones = product_sample.iloc[indices][
        ['product_id', 'categoria_en', 'price']
    ].copy()
    recomendaciones['score'] = valores
    return recomendaciones


# ============================================================
# INTERFAZ
# ============================================================

st.title("Sistema de Recomendacion de Productos")
st.markdown("**Equipo Datalab** | Modelo Content-Based")
st.markdown("---")

# Verificar que el dataset exista antes de continuar
if not os.path.exists("olist_limpio.csv"):
    st.error(
        "No se encontro el archivo olist_limpio.csv. "
        "Ejecute primero el pipeline con: python src/pipeline.py"
    )
    st.stop()

df, product_sample = cargar_y_preparar_datos()

# ============================================================
# SIDEBAR: CONTROLES INTERACTIVOS
# ============================================================
st.sidebar.header("Configuracion del Modelo")

# Seleccion del modelo de similitud
modelo = st.sidebar.radio(
    "Modelo de similitud",
    ["Coseno", "Euclidiana"],
    help="Coseno mide el angulo entre productos. Euclidiana mide la distancia directa."
)

st.sidebar.markdown("---")

# Seleccion de categoria (mostrada en ingles)
categorias = sorted(product_sample['categoria_en'].unique())
categoria_seleccionada = st.sidebar.selectbox(
    "Categoria del producto",
    categorias
)

productos_categoria = product_sample[
    product_sample['categoria_en'] == categoria_seleccionada
]

producto_seleccionado = st.sidebar.selectbox(
    "Producto especifico",
    productos_categoria['product_id'].tolist(),
    format_func=lambda x: f"{x[:12]}... (${productos_categoria[productos_categoria['product_id']==x]['price'].values[0]:.2f})"
)

st.sidebar.markdown("---")
st.sidebar.header("Ajustar Pesos del Modelo")

peso_precio = st.sidebar.slider(
    "Importancia del Precio",
    min_value=0, max_value=100, value=50, step=5,
    help="Que tanto influye el precio en las recomendaciones"
)

peso_categoria = st.sidebar.slider(
    "Importancia de la Categoria",
    min_value=0, max_value=100, value=50, step=5,
    help="Que tanto influye la categoria en las recomendaciones"
)

top_n = st.sidebar.slider(
    "Cantidad de recomendaciones",
    min_value=3, max_value=10, value=5
)

# ============================================================
# PANEL PRINCIPAL
# ============================================================

matriz = calcular_matriz(product_sample, peso_precio, peso_categoria, modelo)

producto_info = product_sample[
    product_sample['product_id'] == producto_seleccionado
].iloc[0]

# Informacion del producto base
st.subheader("Producto Base")
col1, col2, col3, col4 = st.columns(4)
with col1:
    st.metric("Categoria", producto_info['categoria_en'])
with col2:
    st.metric("Precio", f"${producto_info['price']:.2f} BRL")
with col3:
    st.metric("Peso", f"{producto_info['product_weight_g']:.0f} g")
with col4:
    st.metric("Modelo activo", modelo)

st.markdown("---")

# Recomendaciones en formato de tarjetas
st.subheader("Recomendaciones Generadas")

recomendaciones = recomendar(
    producto_seleccionado, product_sample, matriz, modelo, top_n=top_n
)

nombre_score = "Similitud" if modelo == "Coseno" else "Distancia"

for i, (_, rec) in enumerate(recomendaciones.iterrows(), 1):
    col1, col2, col3, col4 = st.columns([1, 4, 2, 2])
    with col1:
        st.markdown(f"### {i}")
    with col2:
        st.markdown(f"**{rec['categoria_en']}**")
        st.caption(f"ID: {rec['product_id'][:20]}...")
    with col3:
        st.metric("Precio", f"${rec['price']:.2f}")
    with col4:
        st.metric(nombre_score, f"{rec['score']:.4f}")
    st.markdown("---")

# Grafico comparativo de scores
st.subheader(f"Scores de {nombre_score}")
chart_data = recomendaciones[['categoria_en', 'score']].copy()
chart_data = chart_data.rename(columns={'categoria_en': 'Categoria', 'score': nombre_score})
st.bar_chart(chart_data.set_index('Categoria'))

# ============================================================
# PIE DE PAGINA
# ============================================================
st.markdown("---")
st.markdown(
    """
    **Informacion del modelo**

    Modelo principal: Content-Based con Similitud Coseno.
    Productos en muestra: {:,} de {:,} unicos.
    Dataset: Brazilian E-Commerce Public Dataset (Olist).
    """.format(len(product_sample), df['product_id'].nunique())
)
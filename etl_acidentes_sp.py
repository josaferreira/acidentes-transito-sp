"""
=============================================================
ETL — ACIDENTES DE TRÂNSITO E CLIMA — SÃO PAULO 2025
=============================================================
Autor: Josafá
Dados:
  - Sinistros: Infosiga SP (https://www.infosiga.sp.gov.br)
  - Clima:     INMET — Estações Mirante (A701) e Interlagos (A771)
  - Shapefile: GeoSampa — Distritos Municipais de SP
=============================================================
"""

import pandas as pd
import geopandas as gpd
from sqlalchemy import create_engine

# ── CAMINHOS — ajuste para o seu ambiente ─────────────────
SINISTROS_PATH   = "dados/sinistros_2022-2026.csv"
MIRANTE_PATH     = "dados/INMET_MIRANTE_2025.csv"
INTERLAGOS_PATH  = "dados/INMET_INTERLAGOS_2025.csv"
DISTRITOS_PATH   = "dados/shapefiles/distrito_municipal_v2.shp"
SINISTROS_OUTPUT = "outputs/acidentes_sp_limpo.csv"
CLIMA_OUTPUT     = "outputs/clima_sp_limpo.csv"

DB_URL = "postgresql://usuario:senha@localhost:5432/acidentes_sp?client_encoding=utf8"


# ══════════════════════════════════════════════════════════
# BLOCO 1 — ETL DE SINISTROS
# ══════════════════════════════════════════════════════════

df_sinistros = pd.read_csv(SINISTROS_PATH, encoding="latin1", sep=";")

df_sinistros = df_sinistros[[
    "id_sinistro", "tipo_registro", "data_sinistro", "ano_sinistro",
    "mes_sinistro", "dia_sinistro", "hora_sinistro", "dia_da_semana",
    "turno", "logradouro", "tipo_via", "latitude", "longitude",
    "municipio", "tp_sinistro_primario"
]]

# Filtros tabulares
df_sinistros = df_sinistros[df_sinistros["tipo_registro"] != "NOTIFICACAO"]
df_sinistros = df_sinistros[df_sinistros["ano_sinistro"] == 2025]
df_sinistros = df_sinistros[df_sinistros["municipio"] == "SAO PAULO"]
df_sinistros = df_sinistros[df_sinistros["latitude"].notna() & (df_sinistros["latitude"].str.strip() != "")]

# Corrigir decimais (padrão brasileiro usa vírgula)
df_sinistros["latitude"]  = df_sinistros["latitude"].str.replace(",", ".").astype(float)
df_sinistros["longitude"] = df_sinistros["longitude"].str.replace(",", ".").astype(float)

# Filtro espacial — manter só pontos dentro do polígono do município de SP
# Necessário pois alguns registros têm município = "SAO PAULO" mas coordenadas fora do município
distritos   = gpd.read_file(DISTRITOS_PATH).to_crs("EPSG:4326")
sp_poligono = distritos.dissolve()

gdf_sinistros = gpd.GeoDataFrame(
    df_sinistros,
    geometry=gpd.points_from_xy(df_sinistros["longitude"], df_sinistros["latitude"]),
    crs="EPSG:4326"
)
gdf_sinistros = gpd.sjoin(gdf_sinistros, sp_poligono, predicate="within")

df_limpo = pd.DataFrame(gdf_sinistros.drop(columns=["geometry", "index_right"]))
df_limpo.to_csv(SINISTROS_OUTPUT, index=False)
print(f"Sinistros exportados: {len(df_limpo)}")


# ══════════════════════════════════════════════════════════
# BLOCO 2 — ETL DE CLIMA
# ══════════════════════════════════════════════════════════

def tratar_inmet(caminho, nome_estacao):
    df = pd.read_csv(caminho, sep=";", encoding="latin1", skiprows=8)
    df = df.drop(columns=["Unnamed: 19"])
    df.columns = [
        "data", "hora_utc", "precipitacao_mm",
        "pressao_estacao", "pressao_max", "pressao_min",
        "radiacao_kj", "temp_bulbo_seco", "temp_orvalho",
        "temp_max", "temp_min", "temp_orvalho_max", "temp_orvalho_min",
        "umidade_max", "umidade_min", "umidade",
        "vento_direcao", "vento_rajada", "vento_velocidade"
    ]

    # Selecionar colunas úteis + as de data
    df = df[["data", "hora_utc", "precipitacao_mm", "umidade", "temp_bulbo_seco", "vento_velocidade"]]

    # Criar data_hora e apagar colunas de data/hora
    df["hora_utc"]  = df["hora_utc"].str.replace(" UTC", "")
    df["data_hora"] = pd.to_datetime(df["data"] + " " + df["hora_utc"], format="%Y/%m/%d %H%M")
    df = df.drop(columns=["data", "hora_utc"])

    # Corrigir decimais
    for col in ["precipitacao_mm", "umidade", "temp_bulbo_seco", "vento_velocidade"]:
        df[col] = df[col].astype(str).str.replace(",", ".").str.strip()
        df[col] = pd.to_numeric(df[col], errors="coerce")

    # Precipitação — preencher vazios com a linha não vazia mais próxima
    df["precipitacao_mm"] = df["precipitacao_mm"].ffill().bfill()

    # Condição de chuva (limiares INMET)
    df["condicao"] = "SEM CHUVA"
    df.loc[df["precipitacao_mm"] > 0,    "condicao"] = "CHUVA FRACA"
    df.loc[df["precipitacao_mm"] >= 2.5, "condicao"] = "CHUVA MODERADA"
    df.loc[df["precipitacao_mm"] >= 7.6, "condicao"] = "CHUVA FORTE"

    # Pista molhada — hora atual + hora anterior + umidade >= 90%
    # RESSALVA: regra heurística, pesos arbitrários, calibração estatística é próximo passo
    # "|" equivale a OR | "&" equivale a AND | "~" equivale a NOT
    precip_anterior = df["precipitacao_mm"].shift(1)
    df["pista_molhada"] = (
        (df["precipitacao_mm"] > 0) |
        (precip_anterior > 0)       |
        (df["umidade"] >= 90)
    )

    df["estacao"] = nome_estacao
    return df


# Aplicar a função, juntar os dataframes e exportar
mirante    = tratar_inmet(MIRANTE_PATH,    "MIRANTE")
interlagos = tratar_inmet(INTERLAGOS_PATH, "INTERLAGOS")
df_clima   = pd.concat([mirante, interlagos], ignore_index=True)
df_clima.to_csv(CLIMA_OUTPUT, index=False)
print(f"Clima exportado: {len(df_clima)}")


# ══════════════════════════════════════════════════════════
# BLOCO 3 — CARGA NO POSTGRESQL
# ══════════════════════════════════════════════════════════

engine = create_engine(DB_URL)

colunas_acidentes = [
    "id_sinistro", "tipo_registro", "data_sinistro", "ano_sinistro",
    "mes_sinistro", "dia_sinistro", "hora_sinistro", "dia_da_semana",
    "turno", "logradouro", "tipo_via", "latitude", "longitude",
    "municipio", "tp_sinistro_primario"
]

df_limpo = pd.read_csv(SINISTROS_OUTPUT, encoding="latin1")
df_limpo = df_limpo[colunas_acidentes]
df_limpo.to_sql("acidentes", engine, if_exists="append", index=False)
print(f"Acidentes importados: {len(df_limpo)}")

df_clima = pd.read_csv(CLIMA_OUTPUT)
df_clima.to_sql("clima", engine, if_exists="append", index=False)
print(f"Registros de clima importados: {len(df_clima)}")

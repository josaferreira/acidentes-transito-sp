# Acidentes de Trânsito em São Paulo — 2025

> Análise espacial de sinistros de trânsito no município de São Paulo, cruzando dados de ocorrências com condições climáticas horárias do INMET. Pipeline completo em Python, modelagem no PostgreSQL/PostGIS e dashboard interativo no Power BI.

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-PostGIS-336791?style=flat&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=flat&logo=powerbi&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat)

---

## Contexto

São Paulo registrou mais de **21 mil sinistros de trânsito** nos primeiros meses de 2025. Este projeto analisa padrões espaciais e temporais desses eventos, cruzando com dados meteorológicos horários de duas estações do INMET (Mirante e Interlagos) para investigar a relação entre condições climáticas e ocorrência/gravidade dos acidentes.

---

## Perguntas centrais

- Quais condições climáticas aumentam a **taxa de fatalidade** dos acidentes?
- Em quais turnos o acidente tem maior **chance de ser fatal**?
- Feriados concentram mais acidentes por dia do que dias normais?
- Quais horários concentram mais acidentes ao longo do dia?

---

## Ressalva metodológica

A variável `pista_molhada` é uma **heurística** baseada em três critérios: precipitação na hora atual, precipitação na hora anterior e umidade relativa ≥ 90%. Os limiares são arbitrários e não foram calibrados estatisticamente. A validação empírica desta regra é um dos próximos passos planejados do projeto.
Os dados históricos utilizados são limitados para o ano de 2025, outro próximo passo será a utilização de uma série histórica considerando mais anos. 

---

## Stack

```
Python      → ETL, análise espacial, visualizações cartográficas
GeoPandas   → manipulação de dados geoespaciais e filtro espacial
PostgreSQL  → modelagem relacional e queries analíticas
PostGIS     → operações espaciais (nearest neighbor, ST_Distance)
Power BI    → dashboard interativo com segmentadores
```

---

## Fontes de dados

| Dado | Fonte | Link |
|------|-------|------|
| Sinistros de trânsito SP | Infosiga SP | [infosiga.sp.gov.br](https://www.infosiga.sp.gov.br) |
| Dados climáticos horários | INMET | [inmet.gov.br](https://www.inmet.gov.br) |
| Distritos municipais SP | GeoSampa | [geosampa.prefeitura.sp.gov.br](https://geosampa.prefeitura.sp.gov.br) |

---

## Estrutura do projeto

```
📦 acidentes-transito-sp/
├── 📂 sql/
│   ├── 01_setup.sql       ← criação do banco, tabelas e dados de referência
│   ├── 02_geometria.sql   ← geometria PostGIS, limpeza e hora_bloco
│   └── 03_views.sql       ← views analíticas e dashboard_final
├── 📂 outputs/
│   ├── hexbin_acidentes_sp.png   ← mapa hexbin exportado
│   └── heatmap_acidentes_sp.html ← mapa de calor interativo
├── etl_acidentes_sp.py    ← pipeline completo Python
├── requirements.txt
└── README.md
```

---

## Como reproduzir

### 1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/acidentes-transito-sp.git
cd acidentes-transito-sp
```

### 2. Instale as dependências
```bash
pip install -r requirements.txt
```

### 3. Baixe os dados
- **Sinistros:** [infosiga.sp.gov.br](https://www.infosiga.sp.gov.br) → Dados Abertos → Sinistros
- **Clima:** [inmet.gov.br](https://www.inmet.gov.br) → BDMEP → Estações A701 (Mirante) e A771 (Interlagos)
- **Shapefile distritos:** [geosampa.prefeitura.sp.gov.br](https://geosampa.prefeitura.sp.gov.br)

### 4. Configure o banco PostgreSQL
```sql
-- Rodar em ordem no pgAdmin ou psql
\i sql/01_setup.sql
\i sql/02_geometria.sql
\i sql/03_views.sql
```

### 5. Configure e rode o pipeline Python
```python
# Edite as variáveis BASE e DB_URL no topo do arquivo
python etl_acidentes_sp.py
```

---

## Principais achados

| Métrica | Valor |
|---------|-------|
| Total de sinistros (2025) | 21.658 |
| Taxa de fatalidade geral | 4,16% |
| Turno mais letal | Madrugada (10,2% de fatalidade) |
| Condição mais letal | Chuva forte (7,4% de fatalidade) |
| Dia da semana com mais acidentes | Sexta-feira |
| Turno com mais volume de sinistros | Tarde |

---

## Próximos passos

- Calibração estatística da heurística `pista_molhada`
- Análise temporal comparativa 2022–2025
- Cruzamento com dados de infraestrutura viária
- Modelo preditivo de risco espacial com ML

---

## Autor

**Josafá**
Estudante de Geografia | Spatial Data Science
[LinkedIn](https://www.linkedin.com/in/josafa-renan-paulino-ferreira-aa0160180/) · [GitHub](https://github.com/josaferreira)

---

*Dados públicos. Projeto sem vínculo com a Prefeitura de São Paulo ou Infosiga.*

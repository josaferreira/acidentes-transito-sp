-- =============================================================
-- 01_setup.sql — Criação do banco e tabelas
-- =============================================================
-- Rodar no banco acidentes_sp (encoding UTF8)

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE acidentes (
    id_sinistro          BIGINT PRIMARY KEY,
    tipo_registro        VARCHAR(50),
    data_sinistro        DATE,
    ano_sinistro         INTEGER,
    mes_sinistro         INTEGER,
    dia_sinistro         INTEGER,
    hora_sinistro        TIME,
    dia_da_semana        VARCHAR(20),
    turno                VARCHAR(20),
    logradouro           TEXT,
    tipo_via             VARCHAR(50),
    latitude             NUMERIC(12, 8),
    longitude            NUMERIC(12, 8),
    municipio            VARCHAR(50),
    tp_sinistro_primario VARCHAR(50),
    geom                 GEOMETRY(Point, 4326)
);

CREATE TABLE estacoes (
    id   SERIAL PRIMARY KEY,
    nome VARCHAR(20),
    geom GEOMETRY(Point, 4326)
);

CREATE TABLE clima (
    id               SERIAL PRIMARY KEY,
    data_hora        TIMESTAMP,
    estacao          VARCHAR(20),
    precipitacao_mm  NUMERIC(6, 2),
    umidade          NUMERIC(5, 2),
    temp_bulbo_seco  NUMERIC(5, 2),
    vento_velocidade NUMERIC(5, 2),
    condicao         VARCHAR(20),
    pista_molhada    BOOLEAN
);

CREATE TABLE feriados (
    data_feriado DATE PRIMARY KEY,
    nome         VARCHAR(100),
    tipo         VARCHAR(20)
);

INSERT INTO estacoes (nome, geom) VALUES
    ('MIRANTE',    ST_SetSRID(ST_MakePoint(-46.6200666, -23.4962888), 4326)),
    ('INTERLAGOS', ST_SetSRID(ST_MakePoint(-46.6774999, -23.7244443), 4326));

INSERT INTO feriados VALUES
    ('2025-01-01', 'Confraternização Universal',   'NACIONAL'),
    ('2025-01-25', 'Aniversário de São Paulo',     'MUNICIPAL'),
    ('2025-03-04', 'Carnaval',                     'NACIONAL'),
    ('2025-03-05', 'Carnaval',                     'NACIONAL'),
    ('2025-04-18', 'Sexta-feira Santa',            'NACIONAL'),
    ('2025-04-20', 'Páscoa',                       'NACIONAL'),
    ('2025-04-21', 'Tiradentes',                   'NACIONAL'),
    ('2025-05-01', 'Dia do Trabalho',              'NACIONAL'),
    ('2025-06-19', 'Corpus Christi',               'NACIONAL'),
    ('2025-07-09', 'Revolução Constitucionalista', 'MUNICIPAL'),
    ('2025-09-07', 'Independência do Brasil',      'NACIONAL'),
    ('2025-10-12', 'Nossa Senhora Aparecida',      'NACIONAL'),
    ('2025-11-02', 'Finados',                      'NACIONAL'),
    ('2025-11-15', 'Proclamação da República',     'NACIONAL'),
    ('2025-11-20', 'Consciência Negra',            'NACIONAL'),
    ('2025-12-25', 'Natal',                        'NACIONAL');

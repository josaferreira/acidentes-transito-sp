-- =============================================================
-- 02_geometria.sql — Geometria, limpeza e coluna hora_bloco
-- =============================================================

-- Índice espacial para performance
CREATE INDEX idx_acidentes_geom ON acidentes USING GIST(geom);

-- Preencher coluna geom com pontos lat/lon
UPDATE acidentes
SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326);

-- Corrigir encoding de dia_da_semana
UPDATE acidentes SET dia_da_semana = 'Sábado'      WHERE dia_da_semana = 'SÃ¡bado';
UPDATE acidentes SET dia_da_semana = 'Terça-feira' WHERE dia_da_semana = 'TerÃ§a-feira';

-- Remover registros com turno não identificado
DELETE FROM acidentes WHERE turno = 'NAO DISPONIVEL';

-- Adicionar coluna hora_bloco (arredondamento para 30min mais próximo)
ALTER TABLE acidentes ADD COLUMN hora_bloco TIME;

UPDATE acidentes
SET hora_bloco = (
    DATE_TRUNC('hour', hora_sinistro::time) +
    ROUND(EXTRACT(MINUTE FROM hora_sinistro) / 30.0) * INTERVAL '30 minutes'
)::TIME;

-- Confirmar
SELECT COUNT(*) FROM acidentes;
SELECT DISTINCT turno FROM acidentes ORDER BY 1;
SELECT DISTINCT dia_da_semana FROM acidentes ORDER BY 1;

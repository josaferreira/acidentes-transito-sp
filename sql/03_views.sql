-- =============================================================
-- 03_views.sql — Views analíticas
-- =============================================================

-- View principal: acidentes + clima + feriado
CREATE VIEW acidentes_com_clima AS
SELECT
    a.id_sinistro,
    a.tipo_registro,
    a.data_sinistro,
    a.ano_sinistro,
    a.mes_sinistro,
    a.dia_sinistro,
    a.hora_sinistro,
    a.hora_bloco,
    a.dia_da_semana,
    a.turno,
    a.logradouro,
    a.tipo_via,
    a.latitude,
    a.longitude,
    a.tp_sinistro_primario,
    e.nome                                            AS estacao_mais_proxima,
    ST_Distance(a.geom::geography, e.geom::geography) AS distancia_metros,
    c.precipitacao_mm,
    c.umidade,
    c.temp_bulbo_seco,
    c.vento_velocidade,
    c.condicao,
    c.pista_molhada,
    CASE WHEN f.data_feriado IS NOT NULL THEN f.nome ELSE 'Dia normal' END AS feriado,
    CASE WHEN f.data_feriado IS NOT NULL THEN f.tipo ELSE 'N/A'        END AS tipo_feriado
FROM acidentes a
CROSS JOIN LATERAL (
    SELECT nome, geom FROM estacoes ORDER BY a.geom <-> geom LIMIT 1
) e
JOIN clima c
    ON  c.estacao   = e.nome
    AND c.data_hora = DATE_TRUNC('hour', (a.data_sinistro + a.hora_sinistro)::TIMESTAMP)
LEFT JOIN feriados f
    ON f.data_feriado = a.data_sinistro;

-- View de exposição por condição climática
CREATE VIEW exposicao_por_condicao AS
SELECT condicao, pista_molhada, COUNT(*) AS horas_exposicao
FROM clima
GROUP BY condicao, pista_molhada;

-- View de taxa por condição climática (normalizada por horas de exposição)
CREATE VIEW taxa_por_condicao AS
SELECT
    e.condicao,
    e.pista_molhada,
    e.horas_exposicao,
    COUNT(a.id_sinistro)                                   AS total_acidentes,
    COUNT(a.id_sinistro)::FLOAT / e.horas_exposicao        AS acidentes_por_hora,
    COUNT(CASE WHEN a.tipo_registro = 'SINISTRO FATAL' THEN 1 END) AS total_fatais,
    COUNT(CASE WHEN a.tipo_registro = 'SINISTRO FATAL' THEN 1 END)::FLOAT /
        NULLIF(COUNT(a.id_sinistro), 0) * 100              AS pct_fatal
FROM exposicao_por_condicao e
LEFT JOIN acidentes_com_clima a
    ON  a.condicao      = e.condicao
    AND a.pista_molhada = e.pista_molhada
GROUP BY e.condicao, e.pista_molhada, e.horas_exposicao;

-- View de taxa por feriado (acidentes por dia)
CREATE VIEW taxa_por_feriado AS
SELECT
    feriado,
    tipo_feriado,
    COUNT(DISTINCT data_sinistro)                              AS dias,
    COUNT(id_sinistro)                                         AS total_acidentes,
    COUNT(id_sinistro)::FLOAT / COUNT(DISTINCT data_sinistro)  AS acidentes_por_dia,
    COUNT(CASE WHEN tipo_registro = 'SINISTRO FATAL' THEN 1 END)::FLOAT /
        NULLIF(COUNT(id_sinistro), 0) * 100                    AS pct_fatal
FROM acidentes_com_clima
GROUP BY feriado, tipo_feriado;

-- View de taxa por turno
CREATE VIEW taxa_por_turno AS
SELECT
    turno,
    COUNT(id_sinistro)                                         AS total_acidentes,
    COUNT(id_sinistro)::FLOAT /
        CASE turno
            WHEN 'MANHA'     THEN 6
            WHEN 'TARDE'     THEN 6
            WHEN 'NOITE'     THEN 6
            WHEN 'MADRUGADA' THEN 6
        END                                                    AS acidentes_por_hora,
    COUNT(CASE WHEN tipo_registro = 'SINISTRO FATAL' THEN 1 END)::FLOAT /
        NULLIF(COUNT(id_sinistro), 0) * 100                    AS pct_fatal
FROM acidentes_com_clima
GROUP BY turno;

-- View consolidada para o Power BI
CREATE VIEW dashboard_final AS
SELECT
    a.id_sinistro,
    a.tipo_registro,
    a.data_sinistro,
    a.ano_sinistro,
    a.mes_sinistro,
    a.dia_sinistro,
    a.hora_sinistro,
    a.hora_bloco,
    a.dia_da_semana,
    a.turno,
    a.tipo_via,
    a.latitude,
    a.longitude,
    a.tp_sinistro_primario,
    c.condicao,
    c.pista_molhada,
    c.precipitacao_mm,
    c.umidade,
    c.temp_bulbo_seco,
    CASE WHEN f.data_feriado IS NOT NULL THEN f.nome ELSE 'Dia normal' END AS feriado,
    CASE WHEN f.data_feriado IS NOT NULL THEN f.tipo ELSE 'N/A'        END AS tipo_feriado,
    tc.acidentes_por_hora AS taxa_acidentes_condicao,
    tc.pct_fatal          AS pct_fatal_condicao,
    tt.pct_fatal          AS pct_fatal_turno
FROM acidentes a
CROSS JOIN LATERAL (
    SELECT nome, geom FROM estacoes ORDER BY a.geom <-> geom LIMIT 1
) e
JOIN clima c
    ON  c.estacao   = e.nome
    AND c.data_hora = DATE_TRUNC('hour', (a.data_sinistro + a.hora_sinistro)::TIMESTAMP)
LEFT JOIN feriados f ON f.data_feriado = a.data_sinistro
LEFT JOIN taxa_por_condicao tc
    ON  tc.condicao      = c.condicao
    AND tc.pista_molhada = c.pista_molhada
LEFT JOIN taxa_por_turno tt ON tt.turno = a.turno;

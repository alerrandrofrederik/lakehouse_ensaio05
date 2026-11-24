-- Silver · lead + empresa (por CNPJ válido) + histórico agregado
CREATE OR REFRESH MATERIALIZED VIEW ${lead_score.catalog}.silver.leads_enriquecidos
COMMENT 'Leads únicos unidos ao cadastro da empresa e ao histórico comercial'
AS SELECT
  l.*,
  e.razao_social AS empresa,
  e.porte, e.segmento, e.num_funcionarios, e.uf,
  coalesce(h.ja_cliente, false) AS ja_cliente,
  coalesce(h.oportunidades_ganhas, 0) AS oportunidades_ganhas,
  coalesce(h.produtos_ganhos, array()) AS produtos_ganhos
FROM ${lead_score.catalog}.silver.leads l
LEFT JOIN ${lead_score.catalog}.silver.empresas e
  ON l.cnpj_valido AND e.cnpj_norm = l.cnpj_norm
LEFT JOIN ${lead_score.catalog}.silver.historico_empresa h
  ON l.cnpj_valido AND h.cnpj_norm = l.cnpj_norm;

-- Silver · histórico comercial agregado por empresa
CREATE OR REFRESH MATERIALIZED VIEW ${lead_score.catalog}.silver.historico_empresa
COMMENT 'Oportunidades por CNPJ: ganhas, perdidas, abertas, produtos já comprados e ja_cliente'
AS SELECT
  regexp_replace(cnpj, '[^0-9]', '') AS cnpj_norm,
  count(*) AS oportunidades,
  count_if(status = 'ganha') AS oportunidades_ganhas,
  count_if(status = 'perdida') AS oportunidades_perdidas,
  count_if(status = 'aberta') AS oportunidades_abertas,
  array_sort(collect_set(CASE WHEN status = 'ganha' THEN produto END)) AS produtos_ganhos,
  coalesce(sum(CASE WHEN status = 'ganha' THEN valor END), 0) AS valor_ganho,
  count_if(status = 'ganha') > 0 AS ja_cliente
FROM ${lead_score.catalog}.bronze.oportunidades_raw
GROUP BY 1;

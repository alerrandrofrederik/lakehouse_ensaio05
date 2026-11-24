-- Silver · empresas com CNPJ normalizado (uma linha por CNPJ)
CREATE OR REFRESH MATERIALIZED VIEW ${lead_score.catalog}.silver.empresas (
  CONSTRAINT cnpj_14_digitos EXPECT (length(cnpj_norm) = 14)
)
COMMENT 'Cadastro de empresas, uma linha por CNPJ normalizado'
AS SELECT cnpj_norm, razao_social, porte, segmento, num_funcionarios, uf
FROM (
  SELECT *,
    regexp_replace(cnpj, '[^0-9]', '') AS cnpj_norm,
    row_number() OVER (PARTITION BY regexp_replace(cnpj, '[^0-9]', '') ORDER BY _ingerido_em DESC) AS rn
  FROM ${lead_score.catalog}.bronze.empresas_raw
)
WHERE rn = 1;

-- Silver · leads normalizados, com CNPJ validado e deduplicados pelo e-mail (fica a mensagem mais recente)
CREATE OR REFRESH MATERIALIZED VIEW ${lead_score.catalog}.silver.leads (
  CONSTRAINT email_valido EXPECT (email_norm RLIKE '^[^@]+@[^@]+[.][^@]+$'),
  CONSTRAINT cnpj_valido_quando_informado EXPECT (cnpj_norm IS NULL OR cnpj_valido),
  CONSTRAINT lead_id_presente EXPECT (lead_id IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT 'Leads únicos por e-mail normalizado, com CNPJ normalizado e dígito verificador validado'
AS
WITH base AS (
  SELECT
    lead_id, nome, email, telefone, canal, campanha, mensagem, recebido_em,
    lower(regexp_replace(email, '[[:space:]]', '')) AS email_norm,
    nullif(regexp_replace(cnpj, '[^0-9]', ''), '') AS cnpj_norm,
    to_date(regexp_extract(_arquivo, '[0-9]{4}-[0-9]{2}-[0-9]{2}', 0)) AS data_arquivo,
    _rescued_data, _arquivo, _ingerido_em
  FROM ${lead_score.catalog}.bronze.leads_raw
),
dv AS (
  SELECT *,
    CASE WHEN length(cnpj_norm) = 14 THEN
      aggregate(sequence(1, 12), 0, (acc, i) ->
        acc + cast(substr(cnpj_norm, i, 1) AS INT) * element_at(array(5,4,3,2,9,8,7,6,5,4,3,2), i)) % 11
    END AS r1,
    CASE WHEN length(cnpj_norm) = 14 THEN
      aggregate(sequence(1, 13), 0, (acc, i) ->
        acc + cast(substr(cnpj_norm, i, 1) AS INT) * element_at(array(6,5,4,3,2,9,8,7,6,5,4,3,2), i)) % 11
    END AS r2
  FROM base
),
validado AS (
  SELECT * EXCEPT (r1, r2),
    coalesce(
      length(cnpj_norm) = 14
      AND cast(substr(cnpj_norm, 13, 1) AS INT) = CASE WHEN r1 < 2 THEN 0 ELSE 11 - r1 END
      AND cast(substr(cnpj_norm, 14, 1) AS INT) = CASE WHEN r2 < 2 THEN 0 ELSE 11 - r2 END,
      false) AS cnpj_valido
  FROM dv
)
SELECT * EXCEPT (rn)
FROM (
  SELECT *, row_number() OVER (PARTITION BY email_norm ORDER BY recebido_em DESC NULLS LAST, lead_id DESC) AS rn
  FROM validado
)
WHERE rn = 1;

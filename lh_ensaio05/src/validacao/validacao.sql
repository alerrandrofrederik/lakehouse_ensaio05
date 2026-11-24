-- Validação dos critérios de aceite (PRD 3.1) · catálogo lh_ensaio05
-- Rode: py -I scripts/sql.py src/validacao/validacao.sql
WITH
gab AS (
  SELECT lead_id, intencao_esperada, nullif(pegadinha, '') AS pegadinha
  FROM read_files('/Volumes/lh_ensaio05/landing/gabarito/intencao.csv', format => 'csv', header => true)
),
ia_vs_gab AS (
  SELECT g.lead_id, g.pegadinha, g.intencao_esperada, i.intencao, g.intencao_esperada = i.intencao AS acertou
  FROM gab g JOIN lh_ensaio05.gold.leads_ia i ON i.lead_id = g.lead_id
),
heroi AS (
  SELECT * FROM lh_ensaio05.gold.leads_classificados WHERE lead_id = 'L20261123-0089'
),
fora_da_fila AS (
  SELECT c.lead_id FROM lh_ensaio05.gold.leads_classificados c
  LEFT ANTI JOIN lh_ensaio05.gold.fila_do_dia f ON f.lead_id = c.lead_id
  WHERE c.intencao = 'compra_imediata'
),
checks AS (
  SELECT 1 AS n, 'CA-01 Bronze: linhas ingeridas' AS criterio, '100' AS esperado,
         cast((SELECT count(*) FROM lh_ensaio05.bronze.leads_raw) AS STRING) AS obtido
  UNION ALL SELECT 2, 'CA-02 Datas malformadas em _rescued_data', '2',
         cast((SELECT count(*) FROM lh_ensaio05.bronze.leads_raw WHERE _rescued_data IS NOT NULL) AS STRING)
  UNION ALL SELECT 3, 'CA-03 Silver: leads únicos', '96',
         cast((SELECT count(*) FROM lh_ensaio05.silver.leads) AS STRING)
  UNION ALL SELECT 4, 'CA-03 E-mails duplicados na Silver', '0',
         cast((SELECT count(*) - count(DISTINCT email_norm) FROM lh_ensaio05.silver.leads) AS STRING)
  UNION ALL SELECT 5, 'CA-03 CNPJs inválidos (cnpj_valido = false)', '2',
         cast((SELECT count(*) FROM lh_ensaio05.silver.leads WHERE cnpj_norm IS NOT NULL AND NOT cnpj_valido) AS STRING)
  UNION ALL SELECT 6, 'CA-04 Reenvio que evolui: sobrevive a compra', 'L20261123-0064',
         (SELECT max(lead_id) FROM lh_ensaio05.silver.leads
          WHERE email_norm = (SELECT lower(regexp_replace(email, '[[:space:]]', '')) FROM lh_ensaio05.bronze.leads_raw WHERE lead_id = 'L20261123-0064'))
  UNION ALL SELECT 7, 'CA-05 Acurácia do ai_classify (%)', '>= 85',
         cast((SELECT round(100 * avg(CASE WHEN acertou THEN 1 ELSE 0 END), 1) FROM ia_vs_gab) AS STRING)
  UNION ALL SELECT 8, 'CA-06 Pegadinhas corretas (de 5)', '>= 4',
         cast((SELECT count_if(acertou) FROM ia_vs_gab WHERE pegadinha IS NOT NULL) AS STRING)
  UNION ALL SELECT 9, 'CA-07 Entidades do herói', 'Atlas Gestão|200|dezembro|true|Diretor Financeiro|OmniERP',
         (SELECT concat_ws('|', produto, cast(qtd_licencas AS STRING), prazo, cast(orcamento_aprovado AS STRING), cargo, concorrente_citado) FROM heroi)
  UNION ALL SELECT 10, 'CA-08 Spam/suporte na fila', '0',
         cast((SELECT count(*) FROM lh_ensaio05.gold.fila_do_dia WHERE intencao IN ('spam', 'suporte')) AS STRING)
  UNION ALL SELECT 11, 'CA-09 Leads na fila', '20',
         cast((SELECT count(*) FROM lh_ensaio05.gold.fila_do_dia) AS STRING)
  UNION ALL SELECT 12, 'CA-09 Vendedores · leads por vendedor (mín/máx)', '4 · 5/5',
         (SELECT concat(count(*), ' · ', min(n), '/', max(n))
          FROM (SELECT vendedor, count(*) AS n FROM lh_ensaio05.gold.fila_do_dia GROUP BY vendedor))
  UNION ALL SELECT 13, 'CA-09 Posição do herói na fila', '1',
         cast((SELECT posicao FROM lh_ensaio05.gold.fila_do_dia WHERE lead_id = 'L20261123-0089') AS STRING)
  UNION ALL SELECT 14, 'Roteiro 1: compra imediata hoje', '26',
         cast((SELECT count(*) FROM lh_ensaio05.gold.leads_classificados WHERE intencao = 'compra_imediata') AS STRING)
  UNION ALL SELECT 15, 'Roteiro 5: compra imediata fora da fila', '6',
         cast((SELECT count(*) FROM fora_da_fila) AS STRING)
)
SELECT
  n, criterio, esperado, obtido,
  CASE
    WHEN esperado LIKE '>= %' THEN CASE WHEN try_cast(obtido AS DOUBLE) >= cast(substr(esperado, 4) AS DOUBLE) THEN '✅' ELSE '❌' END
    WHEN obtido = esperado THEN '✅'
    ELSE '❌'
  END AS status
FROM checks
ORDER BY n

-- Gold · Fila do Dia: os 20 leads de maior score do dia, 5 por vendedor (round-robin pela posição)
CREATE OR REFRESH MATERIALIZED VIEW ${lead_score.catalog}.gold.fila_do_dia
COMMENT 'Os 20 leads priorizados do dia (max(data_arquivo)), distribuídos entre os 4 vendedores'
AS
WITH dia AS (
  SELECT max(data_arquivo) AS data FROM ${lead_score.catalog}.gold.leads_classificados
),
ordenado AS (
  SELECT c.*,
    row_number() OVER (
      ORDER BY c.lead_score DESC, c.score_sinais DESC, c.score_perfil DESC,
               c.qtd_licencas DESC NULLS LAST, c.recebido_em ASC
    ) AS posicao
  FROM ${lead_score.catalog}.gold.leads_classificados c
  JOIN dia ON c.data_arquivo = dia.data
  WHERE c.elegivel_fila
)
SELECT
  data_arquivo AS data,
  posicao,
  element_at(array('Ana Ribeiro', 'Bruno Carvalho', 'Carla Mendes', 'Diego Rocha'), cast((posicao - 1) % 4 + 1 AS INT)) AS vendedor,
  * EXCEPT (posicao)
FROM ordenado
WHERE posicao <= 20;

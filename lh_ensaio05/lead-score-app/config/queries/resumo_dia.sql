-- @param v STRING = 0
-- Números do dia para a Visão do Gestor
WITH dia AS (SELECT max(data_arquivo) AS d FROM lh_ensaio05.gold.leads_classificados)
SELECT
  cast((SELECT d FROM dia) AS STRING) AS dia,
  (SELECT count(*) FROM lh_ensaio05.bronze.leads_raw) AS recebidos,
  (SELECT count(*) FROM lh_ensaio05.gold.leads_classificados, dia WHERE data_arquivo = dia.d) AS unicos,
  (SELECT count(*) FROM lh_ensaio05.gold.leads_classificados, dia WHERE data_arquivo = dia.d AND intencao IS NOT NULL) AS classificados,
  (SELECT count(*) FROM lh_ensaio05.gold.fila_do_dia) AS na_fila,
  (SELECT count(DISTINCT f.lead_id) FROM lh_ensaio05.gold.fila_do_dia f
     JOIN lh_ensaio05.gold.feedback_contatos c ON c.lead_id = f.lead_id) AS contatados,
  (SELECT count(*) FROM lh_ensaio05.gold.leads_classificados, dia WHERE data_arquivo = dia.d AND intencao = 'compra_imediata') AS compra_imediata,
  (SELECT count(*) FROM lh_ensaio05.gold.leads_classificados c
     LEFT ANTI JOIN lh_ensaio05.gold.fila_do_dia f ON f.lead_id = c.lead_id
     WHERE c.intencao = 'compra_imediata') AS compra_fora_da_fila,
  :v AS versao

-- @param v STRING = 0
-- Funil do dia: recebidos → únicos → oportunidade (compra + avaliando) → na fila → contatados
SELECT etapa, leads FROM (
  SELECT 1 AS ordem, 'Recebidos' AS etapa, (SELECT count(*) FROM lh_ensaio05.bronze.leads_raw) AS leads
  UNION ALL SELECT 2, 'Únicos', (SELECT count(*) FROM lh_ensaio05.gold.leads_classificados)
  UNION ALL SELECT 3, 'Compra ou avaliando', (SELECT count(*) FROM lh_ensaio05.gold.leads_classificados WHERE elegivel_fila)
  UNION ALL SELECT 4, 'Na fila', (SELECT count(*) FROM lh_ensaio05.gold.fila_do_dia)
  UNION ALL SELECT 5, 'Contatados', (SELECT count(DISTINCT f.lead_id) FROM lh_ensaio05.gold.fila_do_dia f
                                     JOIN lh_ensaio05.gold.feedback_contatos c ON c.lead_id = f.lead_id)
) WHERE :v IS NOT NULL
ORDER BY ordem

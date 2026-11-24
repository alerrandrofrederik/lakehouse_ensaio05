-- @param v STRING = 0
-- Fila do Dia com o status de contato (v = cache-buster trocado depois de cada contato)
SELECT
  f.posicao, f.vendedor, f.lead_id, f.nome, f.empresa, f.porte, f.cargo, f.canal, f.telefone,
  f.intencao, f.lead_score,
  f.score_intencao, f.score_perfil, f.score_sinais, f.score_recencia,
  f.produto, f.qtd_licencas, f.prazo, f.orcamento_aprovado, f.concorrente_citado,
  f.motivo, f.proximo_passo, f.mensagem, f.data,
  c.lead_id IS NOT NULL AS contatado,
  :v AS versao
FROM lh_ensaio05.gold.fila_do_dia f
LEFT JOIN (SELECT DISTINCT lead_id FROM lh_ensaio05.gold.feedback_contatos) c ON c.lead_id = f.lead_id
ORDER BY f.posicao

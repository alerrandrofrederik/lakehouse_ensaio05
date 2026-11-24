-- Tabela de feedback do app (Delta comum; o app faz INSERT). Parâmetro: catalog.
CREATE TABLE IF NOT EXISTS IDENTIFIER(:catalog || '.gold.feedback_contatos') (
  lead_id      STRING    COMMENT 'Lead contatado',
  vendedor     STRING    COMMENT 'Quem contatou',
  contatado_em TIMESTAMP COMMENT 'Momento do contato',
  resultado    STRING    COMMENT 'contatado | sem_resposta | oportunidade'
) COMMENT 'Feedback do time comercial registrado no Data App';

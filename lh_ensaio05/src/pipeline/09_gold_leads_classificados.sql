-- Gold · todos os leads com intenção, entidades, Lead Score explicável, motivo e próximo passo (PRD 2.7)
CREATE OR REFRESH MATERIALIZED VIEW ${lead_score.catalog}.gold.leads_classificados
COMMENT 'Todos os leads únicos: perfil, intenção, entidades, lead_score (0-100) com os 4 componentes, motivo e próximo passo'
AS
WITH base AS (
  SELECT
    l.lead_id, l.nome, l.email, l.telefone, l.cnpj_norm, l.cnpj_valido,
    l.empresa, l.canal, l.campanha, l.porte, l.segmento, l.uf,
    l.ja_cliente, l.produtos_ganhos, l.mensagem, l.recebido_em, l.data_arquivo,
    i.intencao, i.produto, i.qtd_licencas, i.prazo, i.orcamento_aprovado, i.cargo, i.concorrente_citado,
    i.versao_ia, i.processado_em
  FROM ${lead_score.catalog}.silver.leads_enriquecidos l
  JOIN ${lead_score.catalog}.gold.leads_ia i ON i.lead_id = l.lead_id
),
componentes AS (
  SELECT *,
    CASE intencao WHEN 'compra_imediata' THEN 100 WHEN 'avaliando' THEN 40 ELSE 0 END AS c_intencao,
    least(100,
      CASE porte WHEN 'grande' THEN 100 WHEN 'médio' THEN 60 WHEN 'medio' THEN 60 WHEN 'pequeno' THEN 30 ELSE 20 END
      + CASE WHEN ja_cliente AND (produto IS NULL OR NOT array_contains(produtos_ganhos, produto)) THEN 20 ELSE 0 END
    ) AS c_perfil,
    least(100,
      CASE WHEN coalesce(orcamento_aprovado, false) THEN 40 ELSE 0 END
      + CASE WHEN prazo IS NOT NULL AND trim(prazo) <> '' THEN 30 ELSE 0 END
      + CASE WHEN qtd_licencas IS NOT NULL THEN 30 ELSE 0 END
    ) AS c_sinais,
    CASE
      WHEN recebido_em IS NULL THEN 0
      WHEN datediff(data_arquivo, to_date(recebido_em)) <= 0 THEN 100
      WHEN datediff(data_arquivo, to_date(recebido_em)) = 1 THEN 50
      WHEN datediff(data_arquivo, to_date(recebido_em)) = 2 THEN 25
      ELSE 0
    END AS c_recencia
  FROM base
)
SELECT
  lead_id, nome, email, telefone, empresa, canal, campanha, porte, segmento, uf, ja_cliente,
  cnpj_norm AS cnpj, cnpj_valido, mensagem, intencao,
  produto, qtd_licencas, prazo, orcamento_aprovado, cargo, concorrente_citado,
  CASE WHEN intencao = 'spam' THEN 0
       ELSE cast(round(0.50 * c_intencao + 0.25 * c_perfil + 0.15 * c_sinais + 0.10 * c_recencia) AS INT)
  END AS lead_score,
  named_struct('intencao', c_intencao, 'perfil', c_perfil, 'sinais', c_sinais, 'recencia', c_recencia) AS score_componentes,
  c_intencao AS score_intencao, c_perfil AS score_perfil, c_sinais AS score_sinais, c_recencia AS score_recencia,
  concat_ws(' · ',
    CASE
      WHEN qtd_licencas IS NOT NULL THEN concat('Pediu ', qtd_licencas, ' licenças', coalesce(concat(' do ', produto), ''), coalesce(concat(' até ', prazo), ''))
      WHEN produto IS NOT NULL AND intencao = 'compra_imediata' THEN concat('Quer comprar o ', produto, coalesce(concat(' até ', prazo), ''))
      WHEN produto IS NOT NULL THEN concat('Interesse no ', produto)
      WHEN intencao = 'compra_imediata' THEN 'Pediu proposta ou reunião comercial'
      WHEN intencao = 'avaliando' THEN 'Avaliando opções'
      WHEN intencao = 'suporte' THEN 'Pedido de suporte'
      ELSE 'Sem intenção de compra'
    END,
    CASE WHEN orcamento_aprovado THEN 'orçamento aprovado' END,
    CASE WHEN concorrente_citado IS NOT NULL THEN concat('usa ', concorrente_citado) END,
    cargo,
    CASE WHEN intencao IN ('compra_imediata', 'avaliando') THEN concat('empresa de porte ', coalesce(porte, 'desconhecido')) END,
    CASE WHEN ja_cliente AND intencao IN ('compra_imediata', 'avaliando') THEN 'já é cliente (cross-sell)' END
  ) AS motivo,
  CASE intencao
    WHEN 'spam' THEN 'Descartar'
    WHEN 'suporte' THEN 'Encaminhar ao suporte'
    WHEN 'compra_imediata' THEN
      CASE WHEN qtd_licencas IS NOT NULL OR orcamento_aprovado THEN 'Ligar hoje e enviar proposta'
           ELSE 'Ligar hoje e agendar reunião comercial' END
    WHEN 'avaliando' THEN 'Agendar demonstração'
    ELSE 'Revisar manualmente'
  END AS proximo_passo,
  intencao IN ('compra_imediata', 'avaliando') AS elegivel_fila,
  data_arquivo, recebido_em, processado_em, versao_ia
FROM componentes;

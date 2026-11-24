-- Gold · IA incremental: só linhas novas da Bronze chamam ai_classify/ai_extract (CA-12)
CREATE OR REFRESH STREAMING TABLE ${lead_score.catalog}.gold.leads_ia
COMMENT 'Intenção (ai_classify) e entidades (ai_extract) por linha de lead, com a versão da função'
AS
WITH classificado AS (
  SELECT
    lead_id,
    mensagem,
    CASE
      WHEN mensagem IS NULL OR length(trim(mensagem)) < 5 THEN 'spam'
      ELSE ai_classify(
        mensagem,
        '{
          "compra_imediata": "Quer comprar produtos da Atlas Software: pede preço, proposta, quantidade de licenças, prazo ou reunião comercial",
          "avaliando":       "Quer conhecer os produtos da Atlas, comparar opções ou ver uma demonstração, sem urgência",
          "suporte":         "Já é cliente da Atlas e relata problema, dúvida de uso ou pede ajuda técnica",
          "spam":            "Sem relação com comprar da Atlas: oferta ou propaganda de terceiros (SEO, empréstimo, marketing), teste ou texto sem sentido, mesmo que use palavras como urgente, proposta ou preço"
        }',
        map('version', '2.1')
      ):response[0].value::string
    END AS intencao,
    mensagem IS NULL OR length(trim(mensagem)) < 5 AS regra_mensagem_curta
  FROM STREAM(${lead_score.catalog}.bronze.leads_raw)
),
extraido AS (
  SELECT *,
    CASE WHEN intencao IN ('compra_imediata', 'avaliando') THEN
      ai_extract(
        mensagem,
        '{
          "produto":            {"type": "string",  "description": "Produto Atlas citado"},
          "qtd_licencas":       {"type": "integer", "description": "Quantidade de licenças ou usuários"},
          "prazo":              {"type": "string",  "description": "Prazo ou data desejada, só o mês ou a data, sem preposição (ex.: dezembro)"},
          "orcamento_aprovado": {"type": "boolean", "description": "Mencionou orçamento aprovado"},
          "cargo":              {"type": "string",  "description": "Cargo de quem escreveu"},
          "concorrente_citado": {"type": "string",  "description": "Sistema concorrente de outra empresa que o lead usa ou avalia (nunca um produto Atlas)"}
        }',
        map('version', '2.1')
      )
    END AS entidades_raw
  FROM classificado
)
SELECT
  lead_id,
  intencao,
  regra_mensagem_curta,
  entidades_raw:response.produto.value::string             AS produto,
  entidades_raw:response.qtd_licencas.value::int           AS qtd_licencas,
  entidades_raw:response.prazo.value::string               AS prazo,
  entidades_raw:response.orcamento_aprovado.value::boolean AS orcamento_aprovado,
  entidades_raw:response.cargo.value::string               AS cargo,
  entidades_raw:response.concorrente_citado.value::string  AS concorrente_citado,
  'ai_classify/ai_extract v2.1' AS versao_ia,
  current_timestamp() AS processado_em
FROM extraido;

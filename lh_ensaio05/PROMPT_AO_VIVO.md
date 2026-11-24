# Prompt da demo ao vivo (lh_ensaio05)

> Para outro catálogo ou host, veja a seção **Replicar em outro catálogo ou host** do `CLAUDE.md`.
> Os valores deste arquivo (catálogo `lh_ensaio05`, CSV de 2026-11-23) seguem o `scripts/projeto.env`.

## Checklist antes de subir no palco (T-30 min)
1. `git switch ao-vivo`: branch só com `PRD_v3_lead_score.md`, `CLAUDE.md`, `PROMPT_AO_VIVO.md`, `data/`, `app_referencia/`, `scripts/` e `.claude/`. Ela fica **sem** `src/`, `resources/`, o `databricks.yml` já reescrito e `lead-score-app/`; o template `default-python` fica na raiz. A implementação de referência fica na branch `ensaio-05`.
2. `bash scripts/reset_demo.sh --sim` (só se houve ensaio depois do último reset).
3. `bash scripts/preflight.sh` → precisa terminar em **PRE-FLIGHT OK**. Em host novo, rode duas vezes: a 1ª cria o app e a 2ª aplica os grants.
4. Abrir o Claude Code na raiz do repositório em **auto mode** (sem plan mode), com o terminal em fonte grande.
5. Deixar abertas: a aba do Catalog Explorer em `lh_ensaio05`, a aba da página do pipeline e o arquivo `data/lead_score_dados/raw/leads/leads_2026-11-23.csv`.

## Prompt (copiar e colar)

```
Implemente o PRD_v3_lead_score.md do zero até o Data App no ar, seguindo o CLAUDE.md à risca:
decisões fixas, ordem de execução, receitas e armadilhas. Não faça perguntas e não leia skills
nem docs do AppKit: tudo o que você precisa está no CLAUDE.md. Rode em background os comandos
longos (pipeline e deploy do app) e trabalhe no próximo passo enquanto isso. Antes de subir o
CSV de leads, avise em uma linha "Agora o CSV do dia chega" e pare só para eu dizer "pode subir".
No fim, mostre o resultado do validacao.sql e a URL do app.
```

## Marcos para cronometrar (alvo)
| Marco | Alvo |
|---|---|
| Bundle + pipeline escritos e `bundle deploy` OK | 5 min |
| CSV no Volume e pipeline disparado | 6 min |
| Pipeline concluído | 9 min |
| `validacao.sql` todo verde + Genie Space criado | 10 min |
| `apps validate` OK | 16 min |
| App RUNNING com o código novo | 19 min |
| Herói em #1, "Contatado" gravado e agente respondendo | 20 min |

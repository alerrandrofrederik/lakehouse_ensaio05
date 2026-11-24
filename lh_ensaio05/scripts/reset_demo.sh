#!/usr/bin/env bash
# Reset do Lead Score para reensaiar o build ao vivo.  bash scripts/reset_demo.sh --sim
#
# APAGA (sem volta): pipeline e job do bundle do projeto (LS_CATALOG em projeto.env) (com as tabelas bronze/silver/gold),
# gold.feedback_contatos, os CSVs de raw/leads/, o Genie Space "Lead Score · Agente Comercial" e o
# estado do bundle de dados (remoto e local).
# MANTÉM: catálogo, schemas, volumes, empresas/histórico/gabarito, o app lead-score-app (e o estado
# do bundle dele) e os grants. Não mexe no seu código local (para isso, use git).
# Depois rode scripts/preflight.sh.
set -uo pipefail
export MSYS_NO_PATHCONV=1

if [ "${1:-}" != "--sim" ]; then
  echo "Isto apaga pipeline, tabelas, leads carregados, Genie Space e o estado do bundle de dados."
  echo "Confirme rodando:  bash scripts/reset_demo.sh --sim"
  exit 1
fi

# Configuração do projeto (scripts/projeto.env); variável já exportada tem prioridade
while IFS='=' read -r K V; do
  case "$K" in LS_*) [ -z "${!K:-}" ] && export "$K=${V%$'\r'}" ;; esac
done < "$(dirname "$0")/projeto.env"
P="--profile $LS_PROFILE"
CAT="$LS_CATALOG"
RAIZ="$(cd "$(dirname "$0")/.." && (pwd -W 2>/dev/null || pwd))"
PY="$(command -v py >/dev/null 2>&1 && echo "py -I" || echo "python3 -I")"
SQL="$PY $RAIZ/scripts/sql.py"
json() { $PY -c "import json,sys; sys.stdin.reconfigure(encoding='utf-8'); sys.stdout.reconfigure(encoding='utf-8'); d=json.load(sys.stdin); $1"; }

echo "== Lead Score · reset da demo =="

# 1. Pipeline(s) e job do bundle de dados
for ID in $(databricks pipelines list-pipelines $P -o json | json "print('\n'.join(p['pipeline_id'] for p in d if '${CAT}_pipeline' in p.get('name','')))"); do
  databricks pipelines delete "$ID" $P && echo "🗑️  pipeline $ID"
done
for ID in $(databricks jobs list $P -o json | json "print('\n'.join(str(j['job_id']) for j in d if '${CAT}_setup' in j.get('settings',{}).get('name','')))"); do
  databricks jobs delete "$ID" $P && echo "🗑️  job $ID"
done

# 2. Tabelas que sobrarem em bronze/silver/gold (inclui feedback_contatos)
TABELAS=$($SQL -q -e "SELECT concat_ws('.', table_catalog, table_schema, table_name), table_type FROM $CAT.information_schema.tables WHERE table_schema IN ('bronze','silver','gold')")
while IFS='|' read -r NOME TIPO; do
  NOME=$(echo "$NOME" | xargs); TIPO=$(echo "$TIPO" | xargs)
  [ -z "$NOME" ] && continue
  case "$TIPO" in
    MATERIALIZED_VIEW) $SQL -q -e "DROP MATERIALIZED VIEW IF EXISTS $NOME" ;;
    STREAMING_TABLE)   $SQL -q -e "DROP TABLE IF EXISTS $NOME" ;;
    VIEW)              $SQL -q -e "DROP VIEW IF EXISTS $NOME" ;;
    *)                 $SQL -q -e "DROP TABLE IF EXISTS $NOME" ;;
  esac && echo "🗑️  $NOME ($TIPO)"
done <<< "$TABELAS"

# 3. Leads carregados no Volume
for F in $(databricks fs ls "dbfs:/Volumes/$CAT/landing/raw/leads" $P 2>/dev/null); do
  databricks fs rm "dbfs:/Volumes/$CAT/landing/raw/leads/$F" $P && echo "🗑️  raw/leads/$F"
done

# 4. Genie Space
for ID in $(databricks genie list-spaces $P -o json | json "print('\n'.join(s['space_id'] for s in d.get('spaces',[]) if s.get('title')=='Lead Score · Agente Comercial'))"); do
  databricks genie trash-space "$ID" $P && echo "🗑️  Genie Space $ID"
done

# 5. Estado do bundle de dados (remoto e local): o próximo deploy começa do zero e não toca em schemas/volumes
EU=$(databricks current-user me $P -o json | json "print(d['userName'])")
databricks workspace delete "/Workspace/Users/$EU/.bundle/$CAT" --recursive $P >/dev/null 2>&1 && echo "🗑️  estado remoto do bundle $CAT"
# O bundle está na raiz: apaga só .databricks/bundle (mantém .databricks/aitools)
rm -rf "$RAIZ/.databricks/bundle" && echo "🗑️  estado local do bundle $CAT"

echo
echo "Reset concluído. Agora: bash scripts/preflight.sh"

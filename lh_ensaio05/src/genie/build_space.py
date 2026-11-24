"""Cria o Genie Space "Lead Score · Agente Comercial" sobre as 3 tabelas Gold do lh_ensaio05.

Uso:  py -I src/genie/build_space.py         (imprime o space_id no fim)
"""
import json
import os
import subprocess
import sys
import tempfile
import uuid

_ENV = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "scripts", "projeto.env")
if os.path.exists(_ENV):  # scripts/projeto.env como padrão; variável exportada tem prioridade
    with open(_ENV, encoding="utf-8") as _f:
        for _linha in _f:
            _k, _sep, _v = _linha.strip().partition("=")
            if _sep and _k.startswith("LS_"):
                os.environ.setdefault(_k, _v)

CAT = os.environ.get("LS_CATALOG", "lh_ensaio05")
WAREHOUSE = os.environ.get("LS_WAREHOUSE", "a50e6a998ebe9440")
PROFILE = os.environ.get("LS_PROFILE", "lead_score")
TITULO = "Lead Score · Agente Comercial"
G = f"{CAT}.gold"
HOJE = f"(SELECT max(data_arquivo) FROM {G}.leads_classificados)"

INSTRUCOES = f"""Você é o agente comercial da Atlas Software. Responda sempre em português.
- "Hoje" ou "do dia" = data_arquivo = max(data_arquivo) de {G}.leads_classificados. Nunca use current_date().
- Intenções possíveis (coluna intencao): compra_imediata, avaliando, suporte, spam. "Compra" = compra_imediata.
- "Fila" ou "fila do dia" = {G}.fila_do_dia (20 leads, 5 por vendedor: Ana Ribeiro, Bruno Carvalho, Carla Mendes, Diego Rocha).
- "Fora da fila" = leads de compra_imediata de {G}.leads_classificados LEFT ANTI JOIN {G}.fila_do_dia por lead_id.
- "Contatado" = existe linha em {G}.feedback_contatos para o lead_id.
- lead_score vai de 0 a 100; score_componentes traz intencao, perfil, sinais e recencia.
- Ao listar leads, mostre lead_id, nome, empresa, canal, lead_score e motivo."""

EXEMPLOS = [
    ("Quantos leads de compra imediata chegaram hoje?",
     f"SELECT count(*) AS leads_compra_imediata\nFROM {G}.leads_classificados\n"
     f"WHERE intencao = 'compra_imediata' AND data_arquivo = {HOJE}"),
    ("Qual canal trouxe mais leads de compra imediata?",
     f"SELECT canal, count(*) AS leads_compra_imediata\nFROM {G}.leads_classificados\n"
     f"WHERE intencao = 'compra_imediata' AND data_arquivo = {HOJE}\nGROUP BY canal\nORDER BY leads_compra_imediata DESC"),
    ("Quais leads citaram concorrente?",
     f"SELECT lead_id, nome, empresa, concorrente_citado, intencao, lead_score\nFROM {G}.leads_classificados\n"
     f"WHERE concorrente_citado IS NOT NULL AND data_arquivo = {HOJE}\nORDER BY lead_score DESC"),
    ("Quantos leads da minha fila eu já contatei?",
     f"SELECT f.vendedor, count(DISTINCT f.lead_id) AS leads_na_fila, count(DISTINCT c.lead_id) AS contatados\n"
     f"FROM {G}.fila_do_dia f\nLEFT JOIN {G}.feedback_contatos c ON c.lead_id = f.lead_id\nGROUP BY f.vendedor\nORDER BY f.vendedor"),
    ("Quais leads de compra imediata ficaram fora da fila de hoje?",
     f"SELECT c.lead_id, c.nome, c.empresa, c.canal, c.lead_score, c.motivo\nFROM {G}.leads_classificados c\n"
     f"LEFT ANTI JOIN {G}.fila_do_dia f ON f.lead_id = c.lead_id\n"
     f"WHERE c.intencao = 'compra_imediata' AND c.data_arquivo = {HOJE}\nORDER BY c.lead_score DESC"),
]


def ids(n: int) -> list[str]:
    return sorted(uuid.uuid4().hex for _ in range(n))


def montar() -> dict:
    i_amostras = ids(len(EXEMPLOS))
    i_texto = ids(1)
    i_sql = ids(len(EXEMPLOS))
    tabelas = sorted([f"{G}.feedback_contatos", f"{G}.fila_do_dia", f"{G}.leads_classificados"])
    return {
        "version": 2,
        "config": {
            "sample_questions": [{"id": i, "question": [q]} for i, (q, _) in zip(i_amostras, EXEMPLOS)],
        },
        "data_sources": {"tables": [{"identifier": t} for t in tabelas]},
        "instructions": {
            "text_instructions": [{"id": i_texto[0], "content": [INSTRUCOES]}],
            "example_question_sqls": [
                {"id": i, "question": [q], "sql": [s]} for i, (q, s) in zip(i_sql, EXEMPLOS)
            ],
        },
    }


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    corpo = {
        "warehouse_id": WAREHOUSE,
        "title": TITULO,
        "description": "Perguntas em português sobre os leads do dia, a fila priorizada e os contatos do time comercial.",
        "serialized_space": json.dumps(montar(), ensure_ascii=False),
    }
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(corpo, f, ensure_ascii=False)
        caminho = f.name
    try:
        out = subprocess.run(
            ["databricks", "genie", "create-space", "--json", "@" + caminho, "--profile", PROFILE, "-o", "json"],
            capture_output=True, text=True, encoding="utf-8", shell=(os.name == "nt"),
        )
    finally:
        os.unlink(caminho)
    if out.returncode:
        print(out.stderr or out.stdout, file=sys.stderr)
        return 1
    print(json.loads(out.stdout)["space_id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())

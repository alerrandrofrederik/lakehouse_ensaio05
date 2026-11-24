import { useSyncExternalStore } from 'react';

// O warehouse devolve booleanos e números como texto: normalize antes de usar.
export const bool = (v: unknown): boolean => v === true || v === 'true';
export const num = (v: unknown): number => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
};
export const txt = (v: unknown): string => (v === null || v === undefined ? '' : String(v));

export const VENDEDORES = ['Ana Ribeiro', 'Bruno Carvalho', 'Carla Mendes', 'Diego Rocha'] as const;

export const INTENCAO_ROTULO: Record<string, string> = {
  compra_imediata: 'Compra imediata',
  avaliando: 'Avaliando',
  suporte: 'Suporte',
  spam: 'Spam',
};

// Cache-buster compartilhado: muda depois de cada contato para recarregar as consultas.
let versaoGlobal = String(Date.now());
const ouvintes = new Set<() => void>();

function assinar(fn: () => void) {
  ouvintes.add(fn);
  return () => {
    ouvintes.delete(fn);
  };
}

function trocarVersao() {
  versaoGlobal = String(Date.now());
  ouvintes.forEach((fn) => fn());
}

export function useVersao(): [string, () => void] {
  const versao = useSyncExternalStore(assinar, () => versaoGlobal);
  return [versao, trocarVersao];
}

export async function marcarContatado(leadId: string, vendedor: string): Promise<void> {
  const r = await fetch('/api/contatos', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ lead_id: leadId, vendedor, resultado: 'contatado' }),
  });
  const corpo = (await r.json().catch(() => ({}))) as { ok?: boolean; erro?: string };
  if (!r.ok || !corpo.ok) throw new Error(corpo.erro ?? `HTTP ${r.status}`);
}

import { useState } from 'react';
import {
  useAnalyticsQuery,
  Alert,
  AlertDescription,
  AlertTitle,
  Badge,
  Button,
  Card,
  CardContent,
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
  Label,
  Progress,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Skeleton,
} from '@databricks/appkit-ui/react';
import { sql } from '@databricks/appkit-ui/js';
import { Building2, Check, ListOrdered, PhoneCall, Quote } from 'lucide-react';
import { INTENCAO_ROTULO, VENDEDORES, bool, marcarContatado, num, txt, useVersao } from '../lib/dados';

const TODOS = 'todos';

export function FilaPage() {
  const [versao, trocarVersao] = useVersao();
  const [vendedor, setVendedor] = useState<string>(TODOS);
  const { data, loading, error } = useAnalyticsQuery('fila_do_dia', { v: sql.string(versao) });

  const linhas = (data ?? []).filter((l) => vendedor === TODOS || txt(l.vendedor) === vendedor);
  const contatados = linhas.filter((l) => bool(l.contatado)).length;

  return (
    <div className="space-y-6 max-w-6xl">
      <div>
        <p className="text-xs font-semibold tracking-[0.2em] text-muted-foreground uppercase">Operação → Fila do Dia</p>
        <h2 className="text-3xl font-bold text-foreground flex items-center gap-2 mt-1">
          <ListOrdered className="h-7 w-7" /> Fila do Dia
        </h2>
        <p className="text-muted-foreground mt-1">
          Os 20 leads de maior nota, 5 por vendedor. Cada card mostra por que o lead está na fila e o que fazer na ligação.
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-6">
        <div className="space-y-2">
          <Label htmlFor="vendedor">Vendedor</Label>
          <Select value={vendedor} onValueChange={setVendedor}>
            <SelectTrigger id="vendedor" className="w-56">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={TODOS}>Todos os vendedores</SelectItem>
              {VENDEDORES.map((v) => (
                <SelectItem key={v} value={v}>
                  {v}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        {data && (
          <p className="text-muted-foreground pb-2">
            {contatados} de {linhas.length} contatados
          </p>
        )}
      </div>

      {loading && !data && (
        <div className="space-y-4">
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} className="h-48 w-full" />
          ))}
        </div>
      )}
      {error && (
        <Alert variant="destructive">
          <AlertTitle>Não foi possível carregar a fila</AlertTitle>
          <AlertDescription>{String(error)}</AlertDescription>
        </Alert>
      )}
      {data && linhas.length === 0 && (
        <Empty>
          <EmptyHeader>
            <EmptyTitle>Fila vazia</EmptyTitle>
            <EmptyDescription>Nenhum lead priorizado para hoje. O pipeline já rodou?</EmptyDescription>
          </EmptyHeader>
        </Empty>
      )}

      <div className="space-y-4">
        {linhas.map((l) => (
          <LeadCard key={txt(l.lead_id)} lead={l} aoContatar={trocarVersao} />
        ))}
      </div>
    </div>
  );
}

type Lead = Record<string, unknown>;

function LeadCard({ lead, aoContatar }: { lead: Lead; aoContatar: () => void }) {
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const contatado = bool(lead.contatado);
  const intencao = txt(lead.intencao);

  const componentes = [
    { rotulo: 'Intenção (50%)', valor: num(lead.score_intencao) },
    { rotulo: 'Perfil (25%)', valor: num(lead.score_perfil) },
    { rotulo: 'Sinais (15%)', valor: num(lead.score_sinais) },
    { rotulo: 'Recência (10%)', valor: num(lead.score_recencia) },
  ];
  const entidades = [
    ['Produto', txt(lead.produto)],
    ['Licenças', lead.qtd_licencas === null || lead.qtd_licencas === undefined ? '' : String(num(lead.qtd_licencas))],
    ['Prazo', txt(lead.prazo)],
    ['Orçamento', bool(lead.orcamento_aprovado) ? 'aprovado' : ''],
    ['Concorrente', txt(lead.concorrente_citado)],
  ].filter(([, v]) => v);

  async function contatar() {
    setEnviando(true);
    setErro(null);
    try {
      await marcarContatado(txt(lead.lead_id), txt(lead.vendedor));
      aoContatar();
    } catch (e) {
      setErro(e instanceof Error ? e.message : String(e));
    } finally {
      setEnviando(false);
    }
  }

  return (
    <Card className="shadow-sm">
      <CardContent className="p-6 grid gap-6 md:grid-cols-[1fr_280px]">
        <div className="space-y-3 min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm text-muted-foreground">#{num(lead.posicao)}</span>
            <h3 className="text-xl font-semibold text-foreground">{txt(lead.nome)}</h3>
            <Badge className={intencao === 'compra_imediata' ? 'bg-success text-success-foreground' : 'bg-warning text-warning-foreground'}>
              {INTENCAO_ROTULO[intencao] ?? intencao}
            </Badge>
            <Badge variant="secondary">{txt(lead.vendedor)}</Badge>
            {contatado && (
              <Badge className="bg-success text-success-foreground">
                <Check className="h-3 w-3 mr-1" /> Contatado
              </Badge>
            )}
          </div>
          <div className="flex flex-wrap gap-x-5 gap-y-1 text-sm text-muted-foreground">
            <span className="flex items-center gap-1">
              <Building2 className="h-4 w-4" /> {txt(lead.empresa) || 'Empresa não identificada'}
              {lead.porte ? ` · ${txt(lead.porte)}` : ''}
            </span>
            {lead.cargo ? <span>{txt(lead.cargo)}</span> : null}
            <span>canal: {txt(lead.canal)}</span>
            <span>{txt(lead.telefone)}</span>
          </div>
          <p className="font-medium text-foreground">{txt(lead.motivo)}</p>
          {entidades.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {entidades.map(([k, v]) => (
                <span key={k} className="text-xs rounded-md bg-muted px-2 py-1 text-muted-foreground">
                  {k}: <strong className="text-foreground">{v}</strong>
                </span>
              ))}
            </div>
          )}
          <blockquote className="flex gap-2 rounded-md bg-muted/60 p-3 text-sm text-muted-foreground">
            <Quote className="h-4 w-4 shrink-0 mt-0.5" />
            <span>{txt(lead.mensagem)}</span>
          </blockquote>
        </div>

        <div className="space-y-3 md:border-l md:pl-6">
          <div>
            <p className="text-sm text-muted-foreground">Nota de prioridade</p>
            <p className="text-5xl font-bold text-foreground">{num(lead.lead_score)}</p>
          </div>
          {componentes.map((c) => (
            <div key={c.rotulo} className="space-y-1">
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>{c.rotulo}</span>
                <span>{c.valor}</span>
              </div>
              <Progress value={c.valor} />
            </div>
          ))}
          <div className="rounded-md bg-primary/10 p-3 text-sm text-foreground">
            <strong>Próximo passo:</strong> {txt(lead.proximo_passo)}
          </div>
          <Button className="w-full" variant={contatado ? 'outline' : 'default'} disabled={contatado || enviando} onClick={contatar}>
            <PhoneCall className="h-4 w-4 mr-2" />
            {contatado ? 'Contatado' : enviando ? 'Registrando…' : 'Marcar como contatado'}
          </Button>
          {erro && <p className="text-xs text-destructive">{erro}</p>}
        </div>
      </CardContent>
    </Card>
  );
}

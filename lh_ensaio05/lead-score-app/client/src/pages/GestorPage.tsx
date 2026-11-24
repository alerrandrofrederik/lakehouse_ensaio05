import { useNavigate } from 'react-router';
import {
  useAnalyticsQuery,
  Alert,
  AlertDescription,
  AlertTitle,
  BarChart,
  Button,
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  Skeleton,
} from '@databricks/appkit-ui/react';
import { sql } from '@databricks/appkit-ui/js';
import { ArrowRight, CheckCircle2, Flame, Inbox, ListOrdered, Sparkles, UserX } from 'lucide-react';
import { num, txt, useVersao } from '../lib/dados';

export function GestorPage() {
  const navigate = useNavigate();
  const [versao] = useVersao();
  const parametros = { v: sql.string(versao) };
  const { data, loading, error } = useAnalyticsQuery('resumo_dia', parametros);
  const r = data?.[0];

  const kpis = r
    ? [
        { titulo: 'Recebidos', valor: num(r.recebidos), nota: `${num(r.unicos)} únicos após deduplicação`, fonte: 'bronze.leads_raw', Icone: Inbox },
        { titulo: 'Classificados', valor: num(r.classificados), nota: 'ai_classify + regra de spam', fonte: 'gold.leads_ia', Icone: Sparkles },
        { titulo: 'Na fila', valor: num(r.na_fila), nota: 'capacidade: 4 vendedores × 5', fonte: 'gold.fila_do_dia', Icone: ListOrdered },
        { titulo: 'Contatados', valor: num(r.contatados), nota: `de ${num(r.na_fila)} leads na fila`, fonte: 'gold.feedback_contatos', Icone: CheckCircle2 },
        { titulo: 'Compra imediata', valor: num(r.compra_imediata), nota: 'intenção forte de compra hoje', fonte: 'gold.leads_classificados', Icone: Flame },
        { titulo: 'Fora da fila', valor: num(r.compra_fora_da_fila), nota: 'compra imediata sem vaga hoje', fonte: 'compra − fila', Icone: UserX },
      ]
    : [];

  return (
    <div className="space-y-6 max-w-7xl">
      <div>
        <p className="text-xs font-semibold tracking-[0.2em] text-muted-foreground uppercase">
          Operação comercial · dia de referência {r ? txt(r.dia) : '…'}
        </p>
        <h2 className="text-3xl font-bold text-foreground mt-1">Visão do Gestor</h2>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertTitle>Não foi possível carregar o resumo</AlertTitle>
          <AlertDescription>{String(error)}</AlertDescription>
        </Alert>
      )}

      <Card className="bg-primary text-primary-foreground border-0 shadow-lg">
        <CardContent className="p-8 space-y-4">
          <p className="text-xs font-semibold tracking-[0.2em] uppercase opacity-80">
            {r ? `${num(r.recebidos)} leads · 20 conversas · quais 20?` : '100 leads · 20 conversas · quais 20?'}
          </p>
          {loading && !r ? (
            <Skeleton className="h-10 w-2/3" />
          ) : r ? (
            <>
              <h3 className="text-3xl md:text-4xl font-bold">
                {num(r.na_fila)} leads na fila hoje · {num(r.compra_imediata)} de compra imediata
              </h3>
              <p className="max-w-3xl opacity-90">
                De <strong>{num(r.recebidos)}</strong> leads recebidos, a IA classificou a intenção e extraiu produto, licenças, prazo e orçamento.
                A fila reúne as <strong>{num(r.na_fila)}</strong> maiores notas; <strong>{num(r.compra_fora_da_fila)}</strong> leads de compra
                imediata ficaram de fora por falta de capacidade e <strong>{num(r.contatados)}</strong> já foram contatados.
              </p>
            </>
          ) : null}
          <div className="flex flex-wrap gap-3 pt-2">
            <Button variant="secondary" onClick={() => navigate('/fila')}>
              Ver minha fila <ArrowRight className="h-4 w-4 ml-2" />
            </Button>
            <Button variant="outline" className="bg-transparent text-primary-foreground border-primary-foreground/40" onClick={() => navigate('/agente')}>
              <Sparkles className="h-4 w-4 mr-2" /> Perguntar ao agente
            </Button>
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 grid-cols-2 md:grid-cols-3 xl:grid-cols-6">
        {loading && !r
          ? [0, 1, 2, 3, 4, 5].map((i) => <Skeleton key={i} className="h-36" />)
          : kpis.map(({ titulo, valor, nota, fonte, Icone }) => (
              <Card key={titulo} className="shadow-sm">
                <CardContent className="p-5 space-y-2">
                  <div className="flex items-center justify-between text-muted-foreground">
                    <span className="text-sm">{titulo}</span>
                    <Icone className="h-4 w-4" />
                  </div>
                  <p className="text-3xl font-bold text-foreground">{valor}</p>
                  <p className="text-xs text-muted-foreground">{nota}</p>
                  <p className="text-[10px] tracking-wider uppercase text-muted-foreground">{fonte}</p>
                </CardContent>
              </Card>
            ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="shadow-sm min-w-0">
          <CardHeader>
            <CardTitle>Funil do dia</CardTitle>
          </CardHeader>
          <CardContent>
            <BarChart queryKey="funil_dia" parameters={parametros} xKey="etapa" yKey="leads" orientation="horizontal" />
          </CardContent>
        </Card>
        <Card className="shadow-sm min-w-0">
          <CardHeader>
            <CardTitle>Intenção por canal</CardTitle>
          </CardHeader>
          <CardContent>
            <BarChart
              queryKey="intencao_por_canal"
              parameters={{}}
              xKey="canal"
              yKey={['compra_imediata', 'avaliando', 'suporte', 'spam']}
              stacked
            />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

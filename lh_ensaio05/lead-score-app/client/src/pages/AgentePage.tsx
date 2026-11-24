import { useState } from 'react';
import { Button, Card, CardContent, GenieChat } from '@databricks/appkit-ui/react';
import { Bot, Check, Copy, Flame, Radio, Swords, Target, UserCheck } from 'lucide-react';

const PERGUNTAS = [
  { titulo: 'Leads quentes de hoje', pergunta: 'Quantos leads de compra imediata chegaram hoje?', Icone: Flame },
  { titulo: 'Melhor canal', pergunta: 'Qual canal trouxe mais leads de compra imediata?', Icone: Radio },
  { titulo: 'Concorrentes', pergunta: 'Quais leads citaram concorrente?', Icone: Swords },
  { titulo: 'Meus contatos', pergunta: 'Quantos leads da minha fila eu já contatei?', Icone: UserCheck },
  { titulo: 'Quem ficou de fora', pergunta: 'Quais leads de compra imediata ficaram fora da fila de hoje?', Icone: Target },
];

export function AgentePage() {
  const [copiada, setCopiada] = useState<string | null>(null);

  async function copiar(texto: string) {
    try {
      await navigator.clipboard.writeText(texto);
      setCopiada(texto);
      setTimeout(() => setCopiada(null), 1500);
    } catch {
      setCopiada(null);
    }
  }

  return (
    <div className="space-y-6 max-w-7xl">
      <div>
        <p className="text-xs font-semibold tracking-[0.2em] text-muted-foreground uppercase">Inteligência → Agente · AI/BI Genie</p>
        <h2 className="text-3xl font-bold text-foreground flex items-center gap-2 mt-1">
          <Bot className="h-7 w-7" /> Agente Comercial
        </h2>
        <p className="text-muted-foreground mt-1 max-w-3xl">
          Pergunte em português sobre os leads, a fila e os contatos. O agente consulta as tabelas Gold governadas pelo Unity Catalog e
          mostra o SQL que usou.
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-[340px_1fr]">
        <div className="space-y-3">
          <p className="text-xs font-semibold tracking-[0.2em] text-muted-foreground uppercase">Perguntas do roteiro</p>
          {PERGUNTAS.map(({ titulo, pergunta, Icone }) => (
            <Card key={titulo} className="shadow-sm">
              <CardContent className="p-4 space-y-2">
                <p className="font-semibold text-foreground flex items-center gap-2">
                  <Icone className="h-4 w-4" /> {titulo}
                </p>
                <p className="text-sm text-muted-foreground">{pergunta}</p>
                <Button variant="ghost" size="sm" onClick={() => copiar(pergunta)}>
                  {copiada === pergunta ? <Check className="h-4 w-4 mr-2" /> : <Copy className="h-4 w-4 mr-2" />}
                  {copiada === pergunta ? 'Copiada' : 'Copiar pergunta'}
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
        <div className="h-[min(760px,78vh)] border rounded-lg overflow-hidden bg-card">
          <GenieChat alias="default" />
        </div>
      </div>
    </div>
  );
}

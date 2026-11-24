import { createBrowserRouter, Navigate, NavLink, Outlet, RouterProvider } from 'react-router';
import { useEffect, useState } from 'react';
import { Badge, Button, Sheet, SheetContent, SheetHeader, SheetTitle, useIsMobile } from '@databricks/appkit-ui/react';
import { Bot, LayoutGrid, ListOrdered, Menu, Moon, Sun, Target } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { GestorPage } from './pages/GestorPage';
import { FilaPage } from './pages/FilaPage';
import { AgentePage } from './pages/AgentePage';

type Item = { to: string; titulo: string; sub: string; Icone: LucideIcon };
const SECOES: { nome: string; itens: Item[] }[] = [
  {
    nome: 'Operação',
    itens: [
      { to: '/gestor', titulo: 'Visão do Gestor', sub: 'Funil · Intenção · Canal', Icone: LayoutGrid },
      { to: '/fila', titulo: 'Fila do Dia', sub: '20 leads · 5 por vendedor', Icone: ListOrdered },
    ],
  },
  {
    nome: 'Inteligência',
    itens: [{ to: '/agente', titulo: 'Agente', sub: 'AI/BI Genie', Icone: Bot }],
  },
];

function useTema(): [boolean, () => void] {
  const [escuro, setEscuro] = useState(() => {
    try {
      return localStorage.getItem('tema') === 'escuro';
    } catch {
      return false;
    }
  });
  useEffect(() => {
    const raiz = document.documentElement;
    raiz.classList.toggle('dark', escuro);
    raiz.classList.toggle('light', !escuro);
    try {
      localStorage.setItem('tema', escuro ? 'escuro' : 'claro');
    } catch {
      /* sem storage: só não lembra a escolha */
    }
  }, [escuro]);
  return [escuro, () => setEscuro((e) => !e)];
}

function Sidebar({ onNavegar, escuro, alternarTema }: { onNavegar?: () => void; escuro: boolean; alternarTema: () => void }) {
  return (
    <div className="flex h-full flex-col bg-sidebar text-sidebar-foreground p-5 gap-6">
      <div className="flex items-center gap-3">
        <div className="h-11 w-11 rounded-lg bg-sidebar-primary text-sidebar-primary-foreground flex items-center justify-center">
          <Target className="h-6 w-6" />
        </div>
        <div>
          <p className="font-semibold text-lg leading-tight">Lead Score</p>
          <p className="text-xs opacity-75">Atlas Software · Comercial</p>
        </div>
      </div>

      <nav className="flex-1 space-y-6">
        {SECOES.map((s) => (
          <div key={s.nome} className="space-y-1">
            <p className="px-3 text-[11px] font-semibold tracking-[0.2em] uppercase opacity-60">{s.nome}</p>
            {s.itens.map(({ to, titulo, sub, Icone }) => (
              <NavLink
                key={to}
                to={to}
                onClick={onNavegar}
                className={({ isActive }) =>
                  `flex gap-3 rounded-lg px-3 py-2.5 transition-colors ${
                    isActive ? 'bg-sidebar-accent text-sidebar-accent-foreground' : 'hover:bg-sidebar-accent/60'
                  }`
                }
              >
                <Icone className="h-5 w-5 mt-0.5 shrink-0" />
                <span>
                  <span className="block font-medium">{titulo}</span>
                  <span className="block text-xs opacity-70">{sub}</span>
                </span>
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      <div className="grid grid-cols-2 gap-y-1 text-xs">
        {['SQL Warehouse', 'Genie', 'AI Functions', 'Unity Catalog'].map((s) => (
          <span key={s} className="flex items-center gap-1.5">
            <span className="h-2 w-2 rounded-full bg-success" /> {s}
          </span>
        ))}
      </div>
      <Button
        variant="outline"
        className="bg-transparent border-sidebar-border text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
        onClick={alternarTema}
      >
        {escuro ? <Sun className="h-4 w-4 mr-2" /> : <Moon className="h-4 w-4 mr-2" />}
        {escuro ? 'Tema claro' : 'Tema escuro'}
      </Button>
    </div>
  );
}

function Layout() {
  const isMobile = useIsMobile();
  const [aberto, setAberto] = useState(false);
  const [escuro, alternarTema] = useTema();

  return (
    <div className="min-h-screen bg-background flex">
      <aside className="hidden md:block w-72 shrink-0 sticky top-0 h-screen">
        <Sidebar escuro={escuro} alternarTema={alternarTema} />
      </aside>
      <div className="flex-1 min-w-0 flex flex-col">
        <header className="border-b px-4 md:px-8 py-3 flex items-center gap-3">
          <div className="md:hidden">
            <Sheet open={aberto && isMobile} onOpenChange={setAberto}>
              <Button variant="ghost" size="icon" onClick={() => setAberto(true)}>
                <Menu className="h-5 w-5" />
                <span className="sr-only">Abrir navegação</span>
              </Button>
              <SheetContent side="left" className="p-0 w-72">
                <SheetHeader className="sr-only">
                  <SheetTitle>Navegação</SheetTitle>
                </SheetHeader>
                <Sidebar onNavegar={() => setAberto(false)} escuro={escuro} alternarTema={alternarTema} />
              </SheetContent>
            </Sheet>
          </div>
          <Badge className="ml-auto bg-warning text-warning-foreground">Demo · dados 100% sintéticos</Badge>
        </header>
        <main className="flex-1 p-4 md:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

const router = createBrowserRouter([
  {
    element: <Layout />,
    children: [
      { path: '/', element: <Navigate to="/gestor" replace /> },
      { path: '/gestor', element: <GestorPage /> },
      { path: '/fila', element: <FilaPage /> },
      { path: '/agente', element: <AgentePage /> },
      { path: '*', element: <Navigate to="/gestor" replace /> },
    ],
  },
]);

export default function App() {
  return <RouterProvider router={router} />;
}

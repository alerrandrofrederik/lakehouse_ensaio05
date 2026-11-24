import { createApp, analytics, genie, server, getExecutionContext, getWarehouseId } from '@databricks/appkit';

const CATALOGO = 'lh_ensaio05';
const VENDEDORES = ['Ana Ribeiro', 'Bruno Carvalho', 'Carla Mendes', 'Diego Rocha'];

createApp({
  plugins: [analytics(), genie(), server()],
  async onPluginsReady(appkit) {
    appkit.server.extend((app) => {
      // RF-14: "Marcar como contatado" grava em gold.feedback_contatos
      app.post('/api/contatos', async (req, res) => {
        const corpo = (req.body ?? {}) as { lead_id?: unknown; vendedor?: unknown; resultado?: unknown };
        const leadId = typeof corpo.lead_id === 'string' ? corpo.lead_id.trim() : '';
        const vendedor = typeof corpo.vendedor === 'string' ? corpo.vendedor : '';
        const resultado = typeof corpo.resultado === 'string' ? corpo.resultado : 'contatado';
        if (!/^L[0-9]{8}-[0-9]{4}$/.test(leadId) || !VENDEDORES.includes(vendedor)) {
          res.status(400).json({ ok: false, erro: 'lead_id ou vendedor inválido' });
          return;
        }
        try {
          const { client } = getExecutionContext();
          const warehouseId = await getWarehouseId();
          const r = await client.statementExecution.executeStatement({
            warehouse_id: warehouseId,
            wait_timeout: '30s',
            statement:
              `INSERT INTO ${CATALOGO}.gold.feedback_contatos (lead_id, vendedor, contatado_em, resultado) ` +
              `VALUES (:lead_id, :vendedor, current_timestamp(), :resultado)`,
            parameters: [
              { name: 'lead_id', value: leadId, type: 'STRING' },
              { name: 'vendedor', value: vendedor, type: 'STRING' },
              { name: 'resultado', value: resultado, type: 'STRING' },
            ],
          });
          const estado = r.status?.state;
          if (estado !== 'SUCCEEDED') {
            res.status(500).json({ ok: false, erro: r.status?.error?.message ?? `estado ${estado}` });
            return;
          }
          res.json({ ok: true });
        } catch (e) {
          res.status(500).json({ ok: false, erro: e instanceof Error ? e.message : String(e) });
        }
      });
    });
  },
}).catch(console.error);

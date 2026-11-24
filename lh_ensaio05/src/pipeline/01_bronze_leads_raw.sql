-- Bronze · leads como vieram do formulário (Auto Loader: cada arquivo é lido uma vez)
CREATE OR REFRESH STREAMING TABLE ${lead_score.catalog}.bronze.leads_raw (
  CONSTRAINT recebido_em_valido EXPECT (recebido_em IS NOT NULL)
)
COMMENT 'Leads crus do Volume raw/leads, com _arquivo, _ingerido_em e _rescued_data'
AS SELECT
  *,
  _metadata.file_path AS _arquivo,
  current_timestamp() AS _ingerido_em
FROM STREAM read_files(
  '/Volumes/${lead_score.catalog}/landing/raw/leads/',
  format => 'csv',
  header => true,
  multiLine => true,
  timestampFormat => 'yyyy-MM-dd HH:mm:ss',
  schemaHints => 'lead_id STRING, telefone STRING, cnpj STRING, campanha STRING, mensagem STRING, recebido_em TIMESTAMP',
  rescuedDataColumn => '_rescued_data'
);

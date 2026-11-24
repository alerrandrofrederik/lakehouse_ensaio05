-- Grants do service principal do app lead-score-app no catálogo lh_ensaio05 (gerado por scripts/preflight.sh).
GRANT USE CATALOG ON CATALOG lh_ensaio05 TO `cf7441c1-ce08-4a33-b5e7-4a0b46480ef4`;
GRANT USE SCHEMA, SELECT ON SCHEMA lh_ensaio05.gold TO `cf7441c1-ce08-4a33-b5e7-4a0b46480ef4`;
GRANT MODIFY ON SCHEMA lh_ensaio05.gold TO `cf7441c1-ce08-4a33-b5e7-4a0b46480ef4`;
GRANT USE SCHEMA, SELECT ON SCHEMA lh_ensaio05.bronze TO `cf7441c1-ce08-4a33-b5e7-4a0b46480ef4`;
GRANT USE SCHEMA ON SCHEMA lh_ensaio05.landing TO `cf7441c1-ce08-4a33-b5e7-4a0b46480ef4`;
GRANT READ VOLUME ON VOLUME lh_ensaio05.landing.gabarito TO `cf7441c1-ce08-4a33-b5e7-4a0b46480ef4`;

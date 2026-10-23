# Architecture

## Trigger model
Two independent entry events, each with its **own** Drive folder (a workflow must never write into another workflow's input folder):

1. Rent-platform export arrives → Workflow 1A.
2. Bank statement arrives → Workflow 1B.

Workflow 1C imports the client's own control spreadsheet (room rotations, repairs, partial payments), which the rent platform does not export. The chain 2 → 3 → 4 → 5 → 6 → 7 runs afterwards, also on a monthly schedule as a fallback. Child workflows are called with *Execute Workflow*, which runs the **published** version of the child.

## Infrastructure
VPS (Ubuntu 24.04) with Docker Compose: `n8n`, `postgres`, `gotenberg`. Only n8n is exposed, behind Caddy with HTTPS. Secrets come from an `.env` file via variables. Daily `pg_dump` at 03:00, 30-day retention, documented restore.

## Data model
| Table | Purpose |
|---|---|
| `propiedades`, `propietarios` | Master data |
| `movimientos` | Every income/expense, raw row kept in `origen_raw` |
| `regularizacion_bancaria` | Bank view of payments, to reconcile against `movimientos` |
| `liquidaciones` | Monthly result per property, `UNIQUE(propiedad_id, mes)` |
| `colaboradores`, `colaborador_servicios` | External collaborators and their services |
| `configuracion` | Key/value business parameters |
| `logs` | Execution trace |

### Deduplication
Each source has its own key, because a single key does not work for all of them:
- Rent-platform rows: `UNIQUE (propiedad_id, fecha, de_a, monto, tipo, descripcion)`.
- Bank rows start with `propiedad_id = NULL`, and `NULL` never equals `NULL` in SQL, so that key would never match. They use `UNIQUE (id_transaccion_banco)` (the bank's own ID).
- Rows from the client's control spreadsheet use `UNIQUE (referencia_original)` (date_code_type_amount).

Every insert is `ON CONFLICT ... DO NOTHING`, so the same file can be uploaded twice safely.

Verification: all SQL embedded in the workflows was extracted and run against `database/schema.sql`; every referenced table and column exists.

## Error handling
A global Error Handler workflow emails an alert when any workflow fails; a Logs sub-workflow records each run.

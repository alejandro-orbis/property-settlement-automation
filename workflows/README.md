# Workflows

The 13 workflows of the system, sanitized (credentials, Drive/Sheets IDs, emails, domains and client names removed; all set to inactive).

| File | Workflow |
|---|---|
| `workflow_1a_importacion_rentila.json` | 1A · Rent-platform import |
| `workflow_1b_importacion_banco.json` | 1B · Bank statement import |
| `workflow_1c_importacion_registro.json` | 1C · Control-sheet import |
| `workflow_2_normalizacion.json` | 2 · Normalization |
| `workflow_3_validacion.json` | 3 · Validation / reconciliation |
| `workflow_4_colaboradores.json` | 4 · Collaborators |
| `workflow_5_motor_de_reglas.json` | 5 · Rules engine |
| `workflow_6_exportaciones.json` | 6 · Exports (PDF, invoice data, email) |
| `workflow_7_rentabilidad.json` | 7 · Profitability summary |
| `workflow_8_detalle_de_movimientos.json` | 8 · Movement detail (manual) |
| `panel_de_revision.json` | Review panel (manual) |
| `logs_subworkflow.json` | Logs sub-workflow |
| `error_handler_notificaciones.json` | Global error handler |

Numbers follow the data flow: 1A/1B/1C → 2 → 3 → 4 → 5 → 6 → 7 (workflow 7 is called once, when the loop in 6 finishes). 8 and the review panel are run manually.

To sanitize new exports: `python tools/sanitize_workflows.py export.json --out workflows/ --redact-file private_terms.txt [--renumber "1=1A,7=6,8=7,9=8"]` (keep `private_terms.txt` outside the repository).

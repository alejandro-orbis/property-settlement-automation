# Business rules (example configuration)

All values live in the `configuracion` table; the numbers below are the example defaults in `seed_demo.sql`.

| Rule | Default |
|---|---|
| Management fee — traditional rental | 6 % of rent income |
| Management fee — by rooms | 10 % |
| Management fee — tourist | 20 % |
| VAT | 21 % on fees, expenses charged, repairs, rotations and collaborator costs |
| Repairs | base cost + 40 % margin |
| Room turnover (owner) | fixed fee (75 € by default, `rotacion_habitaciones_propietario`) |
| Room turnover (tenant) | separate invoice to the tenant (`rotacion_habitaciones_inquilino`) |
| Traditional turnover | one month of rent + VAT |
| Threshold | if a repair or traditional rotation exceeds 500 € **VAT included**, it is invoiced separately instead of deducted |

```
net = income − expenses − fees − VAT − rotations − repairs − collaborator costs
```

## Reconciliation states
- `validado`: exact match with the bank.
- `pago_parcial`: known payer, lower amount; the amount actually collected is stored in `monto_cobrado` and used for the settlement.
- `descuadrado`: bank movement of the same payer but the amount does not match (e.g. grouped transfers).
- `pendiente_validar`: no bank movement found.

A settlement with any non-validated movement is marked `pendiente` and **is not emailed**; it appears in a review sheet.

## Direct-collection properties
When the owner collects rent directly from the tenant, no payout is made: only the fees (+ VAT) are invoiced, with status `factura_aparte`.

## Principle
The system never invents or forces a doubtful result: it flags it for a person.

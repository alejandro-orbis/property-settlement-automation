-- Fictional demo data. No real people, addresses or amounts.
-- Percentages: fees are fractions (0.06 = 6 %); reparaciones_margen_pct is expressed in percent (40).
INSERT INTO configuracion (clave, valor) VALUES
 ('iva','0.21'),
 ('tradicional_pct','0.06'),
 ('habitaciones_pct','0.10'),
 ('turistico_pct','0.20'),
 ('reparaciones_margen_pct','40'),
 ('reparaciones_umbral_abono','500'),
 ('rotacion_habitaciones_propietario','75'),
 ('rotacion_habitaciones_inquilino','150'),
 ('colaborador_captacion_tarifa','100'),
 ('colaborador_captacion_tradicional_tarifa','60'),
 ('colaborador_captacion_visitas_incluidas','2'),
 ('colaborador_captacion_visita_extra','15'),
 ('colaborador_captacion_visitas_extra_max','3'),
 ('colaborador_incidencia_tarifa_hora','20'),
 ('colaborador_incidencia_minimo_horas','1'),
 ('colaborador_salida_vivienda_completa','80'),
 ('colaborador_salida_habitacion','30'),
 ('colaborador_servicio_adicional_tarifa_hora','20'),
 ('colaborador_servicio_adicional_minimo_min','30');

INSERT INTO propietarios (nombre, email) VALUES
 ('Owner Demo A','owner.a@example.com'),
 ('Owner Demo B','owner.b@example.com');

INSERT INTO propiedades (codigo_rentila, direccion, propietario_id, tipo_gestion_default, cobro_directo_propietario) VALUES
 ('DEMO_001','Calle Ejemplo 1, 1A',1,'habitaciones',FALSE),
 ('DEMO_002','Calle Ejemplo 2, 3B',1,'tradicional',FALSE),
 ('DEMO_003','Avenida Muestra 10',2,'tradicional',TRUE);

INSERT INTO movimientos (propiedad_id, fecha, de_a, monto, tipo, descripcion, estado, estado_validacion) VALUES
 (1,'2026-07-01','Tenant 1',400,'Alquiler','Alquiler 01/07/2026 - 31/07/2026','Pagado','validado'),
 (1,'2026-07-01','Tenant 2',400,'Alquiler','Alquiler 01/07/2026 - 31/07/2026','Pagado','validado'),
 (1,'2026-07-05','Cleaning SL',60,'Gasto_Limpieza','Limpieza','Pagado','validado'),
 (2,'2026-07-01','Tenant 3',900,'Alquiler','Alquiler 01/07/2026 - 31/07/2026','Pagado','validado'),
 (3,'2026-07-01','Tenant 4',700,'Alquiler','Alquiler 01/07/2026 - 31/07/2026','Pagado','validado');

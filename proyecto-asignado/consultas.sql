-- Consultas para ejecutar directamente sobre la base del proyecto asignado (Ejercicio 2.4)
-- Uso: docker compose exec db psql -U postgres -d datawarehouse -f /dev/stdin < consultas.sql
--  o bien, una por una dentro de: docker compose exec db psql -U postgres -d datawarehouse

-- 1) Verificar que la carga terminó: filas por tabla
SELECT 'dim_sismos' AS tabla, COUNT(*) FROM dim_sismos
UNION ALL SELECT 'dim_tiempo', COUNT(*) FROM dim_tiempo
UNION ALL SELECT 'dim_zonas', COUNT(*) FROM dim_zonas
UNION ALL SELECT 'dim_economia', COUNT(*) FROM dim_economia
UNION ALL SELECT 'fact_impacto_sismos_imputed', COUNT(*) FROM fact_impacto_sismos_imputed;
-- Esperado: 319592, 319592, 32, 32, 196576

-- 2) Sismos por entidad (solo los que tienen fila de hechos)
SELECT z.nom_ent, COUNT(*) AS sismos, ROUND(AVG(s.magnitud)::numeric, 2) AS magnitud_media, MAX(s.magnitud) AS maxima
FROM fact_impacto_sismos_imputed f
JOIN dim_sismos s ON s.id_sismo = f.id_sismo
JOIN dim_zonas  z ON z.id_zonas = f.id_zonas
GROUP BY z.nom_ent ORDER BY sismos DESC LIMIT 10;
-- Esperado (primeras filas): Oaxaca 112905, Guerrero 50596, Jalisco 11101, Colima 9244 ...

-- 3) Hallazgo: sismos que quedan fuera de la tabla de hechos
SELECT CASE WHEN s.estado = '' THEN '(estado vacío)' ELSE s.nombre_estado END AS estado, COUNT(*)
FROM dim_sismos s
WHERE NOT EXISTS (SELECT 1 FROM fact_impacto_sismos_imputed f WHERE f.id_sismo = s.id_sismo)
GROUP BY 1 ORDER BY 2 DESC;
-- Esperado: (estado vacío) 115897, Veracruz 6178, Mexico 584, San Luis Potosi 337, Queretaro 15, Yucatan 5

-- 4) Hallazgo: los sismos más fuertes del catálogo y si aparecen en los mapas
SELECT s.magnitud, t.fecha, s.referencia_de_localizacion, NULLIF(s.nombre_estado, '') AS estado,
       EXISTS (SELECT 1 FROM fact_impacto_sismos_imputed f WHERE f.id_sismo = s.id_sismo) AS en_hechos
FROM dim_sismos s JOIN dim_tiempo t ON t.id_tiempo = s.id_sismo
WHERE s.magnitud >= 7.8 ORDER BY s.magnitud DESC, t.fecha;
-- Esperado: 2017-09-07 M8.2 Pijijiapan, CHIS -> en_hechos = false ; 1985-09-19 M8.1 La Mira, MICH -> false

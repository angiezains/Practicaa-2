# Levantamiento del proyecto asignado — Sistema de visualización de datos sísmicos

| Dato | Valor |
|---|---|
| Repositorio original | https://github.com/gabrielhuav/Seismic-Data-Visualization-System |
| Fork del equipo | `https://github.com/<USUARIO>/Seismic-Data-Visualization-System` ← **completar** |
| Confirmación puesta en funcionamiento | `8569667cf4f46fab640dba3f82a7b324ca7efaf7` (8 may 2026, *Add citation info and BibTeX to README*) |
| Equipo donde se ejecutó | `<SO, versión de Docker, RAM>` ← **completar** (salida de `docker version` y `docker compose version`) |
| Fecha | `<dd/mm/aaaa>` ← **completar** |

> Este archivo documenta los pasos **en el orden en que los ejecutamos**. Las secciones marcadas con ✍️ se llenan con lo que realmente apareció en nuestra terminal; las capturas van en `evidencias/`.

## 1. Requisitos

- Git.
- Docker Desktop (Windows/macOS) o Docker Engine + plugin Compose (Linux). Docker Compose v2 (`docker compose`).
- **≈ 2 GB libres en disco**: los scripts SQL pesan ≈ 176 MB y PostgreSQL los expande en el volumen.
- Puertos libres: **80** (Apache/PHP) y **5433** (PostgreSQL expuesto al anfitrión).
- Opcional: cliente `psql` o DBeaver para conectarse desde fuera (puerto 5433).

## 2. Pasos ejecutados

```bash
# 2.1 Fork en GitHub (botón Fork) y clonación del fork — NO dentro del repositorio del equipo
git clone https://github.com/<USUARIO>/Seismic-Data-Visualization-System.git
cd Seismic-Data-Visualization-System
git checkout 8569667          # fijamos la confirmación que pusimos en funcionamiento
git log -1 --oneline

# 2.2 Verificar que los SQL se descargaron completos (no son punteros LFS)
ls -lh sql/                   # 02-dim_tiempo ≈ 42 MB, 03-dim_sismos ≈ 70 MB, 05-fact ≈ 57 MB

# 2.3 Construir y levantar los contenedores
docker compose up -d --build

# 2.4 Seguir la inicialización de la base (TARDA: son ~840 000 INSERT individuales)
docker compose logs -f db
# esperar hasta ver:  "PostgreSQL init process complete; ready for start up."
#                y luego "database system is ready to accept connections"

# 2.5 Comprobar los servicios
docker compose ps

# 2.6 Abrir la aplicación
#   http://localhost/vista.html   (menú principal)
#   http://localhost/std.php      (mapa de sismos)
#   http://localhost/test.php     (prueba de conexión: lista las tablas)

# 2.7 Consulta directa sobre la base (Ejercicio 2.4)
docker compose exec db psql -U postgres -d datawarehouse
#   dentro de psql, ejecutar las consultas de consultas.sql
#   o desde fuera:  psql -h localhost -p 5433 -U postgres -d datawarehouse -f consultas.sql
```

✍️ **Tiempo real de inicialización de la base en nuestro equipo:** `____ min`

## 3. Problemas detectados al revisar el repositorio (antes de ejecutar)

Los encontramos leyendo `README.md`, `docker-compose.yml`, `Dockerfile` y `src/*.php`. Sirven para anticipar errores y son la base de varias propuestas del ejercicio 6.

| # | Problema | Efecto esperado | Solución / rodeo |
|---|---|---|---|
| 1 | El README indica `git clone https://github.com/gabrielhuav/DWSismos.git` y `cd DWSismos`, pero el repositorio se llama `Seismic-Data-Visualization-System`. | El comando del README falla o clona otro proyecto. | Clonar el fork con su nombre real (paso 2.1). |
| 2 | El README pide seguir “las instrucciones del directorio `data/`”, que no existe. El script Python de validación que describe el artículo tampoco está en el repositorio: solo vienen los SQL ya generados. | No hay forma de regenerar el ETL; los datos terminan el 2025-04-03. | No hace falta: la carga ocurre sola con `docker-entrypoint-initdb.d`. Se documenta como limitación (propuesta P1.3). |
| 3 | No hay `index.php` ni `index.html`. | `http://localhost/` muestra un listado del directorio o *403 Forbidden*. | Entrar por `http://localhost/vista.html`. |
| 4 | La base tarda varios minutos en cargar los ~840 000 INSERT y el compose no tiene *healthcheck*. | Si se abre la aplicación antes de tiempo aparece un error de conexión o de “relation … does not exist”. | Esperar al mensaje de “ready to accept connections” (paso 2.4) y recargar. |
| 5 | `src/datos_sismicos.php` usa `$host = 'localhost'` y contraseña `secreto`. | Dentro del contenedor web, `localhost` no es la base: la página falla con *could not connect to server / Connection refused*. | Cambiar a `$host = getenv('POSTGRES_HOST') ?: 'db';` en nuestro fork (la contraseña no importa porque el compose usa `POSTGRES_HOST_AUTH_METHOD=trust`). |
| 6 | El puerto 80 suele estar ocupado en Windows (IIS, Skype, otro servidor). | `Bind for 0.0.0.0:80 failed: port is already allocated`. | Cambiar en `docker-compose.yml` a `"8080:80"` y entrar por `http://localhost:8080/vista.html`. |
| 7 | `docker-compose.yml` declara `version: '3.8'`. | Aviso *the attribute `version` is obsolete* (no impide el arranque). | Ignorar o eliminar la línea. |
| 8 | Si se interrumpe la primera inicialización, el volumen `postgres_data` queda a medias y los scripts **no se vuelven a ejecutar**. | Tablas vacías o faltantes en arranques posteriores. | `docker compose down -v` y volver a `docker compose up -d --build`. |
| 9 | `sismo.php` y `sismos.php` unen `dim_sismos` con `dim_tiempo` por `ds.id_sismo = dt.id_tiempo`. | Funciona solo porque ambos identificadores coinciden; no es un error visible, pero es frágil. | Se documenta en el ejercicio 5. |

## 4. Errores que aparecieron en nuestra ejecución ✍️

| Paso | Mensaje de error (copiar exacto) | Causa | Cómo lo resolvimos |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |

*(Si no hubo errores en algún paso, escribir “sin errores”. Si algún paso no se logró, indicar en cuál falla y con qué mensaje, y que se consultó al docente.)*

## 5. Consulta ejecutada sobre la base y resultado

Se ejecutaron las consultas de [`consultas.sql`](consultas.sql). Resultado de la consulta 1 (conteos) y de la consulta 4 (sismos M ≥ 7.8):

✍️ *Pegar aquí la salida de psql.* Valores esperados según los scripts de carga:

```
            tabla            | count
-----------------------------+--------
 dim_sismos                  | 319592
 dim_tiempo                  | 319592
 dim_zonas                   |     32
 dim_economia                |     32
 fact_impacto_sismos_imputed | 196576
```

La consulta 4 muestra que el sismo M8.2 del 7 de septiembre de 2017 (140 km al SO de Pijijiapan, Chis.) y el M8.1 del 19 de septiembre de 1985 (La Mira, Mich.) tienen `en_hechos = false`: como `std.php` y `datos_sismicos.php` unen con la tabla de hechos, **esos sismos no aparecen en los mapas**. Lo verificamos además en la aplicación filtrando el año 2017 ✍️ *(captura `evidencias/08-sismo-2017-ausente.png`)*.

## 6. Evidencias (carpeta `evidencias/`)

| Archivo | Contenido |
|---|---|
| `01-clone-checkout.png` | Terminal: clonación del fork y `git log -1` en 8569667 |
| `02-compose-up.png` | Terminal: `docker compose up -d --build` |
| `03-db-ready.png` | Terminal: log de `db` con *ready to accept connections* |
| `04-compose-ps.png` | Terminal: `docker compose ps` con ambos servicios *Up* |
| `05-app-vista.png` | Navegador: `vista.html` funcionando en nuestro equipo (se ve `localhost` en la barra) |
| `06-app-mapa.png` | Navegador: mapa de sismos con filtros aplicados |
| `07-consulta-psql.png` | Terminal: consultas de `consultas.sql` con su resultado |
| `08-sismo-2017-ausente.png` | (opcional) Mapa filtrado en 2017 sin el M8.2 de Chiapas |

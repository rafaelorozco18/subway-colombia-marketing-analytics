# =============================================================================
# MMM SUBWAY COLOMBIA — ROBYN + GOOGLE TRENDS
# Variable dependiente: índice de búsquedas semanales (proxy de demanda)
# Fuentes de medios: BASE_COMPETENCIA_SUBWAY.xlsx + BASE_DIGITAL_SUBWAY_COMPETENCIA.xlsx
# =============================================================================

# -----------------------------------------------------------------------------
# 0. INSTALAR Y CARGAR PAQUETES
# -----------------------------------------------------------------------------
packages <- c("tidyverse", "lubridate", "readxl", "gtrendsR", "Robyn", "reticulate")

installed <- rownames(installed.packages())
to_install <- packages[!packages %in% installed]
if (length(to_install) > 0) install.packages(to_install)

# Robyn desde GitHub si aún no está instalado
if (!"Robyn" %in% installed) {
  remotes::install_github("facebookexperimental/Robyn/R", ref = "main")
}

library(tidyverse)
library(lubridate)
library(readxl)
library(gtrendsR)
library(Robyn)

# Configurar Python para Nevergrad (solo la primera vez)
# reticulate::install_miniconda()
# Robyn::robyn_python()


# -----------------------------------------------------------------------------
# 1. DESCARGAR GOOGLE TRENDS — variable dependiente
# -----------------------------------------------------------------------------
# gtrendsR consulta en tiempo real; si hay límite de API espera unos minutos y reintenta.

trends_raw <- gtrends(
  keyword    = "Subway",       # término exacto de búsqueda
  geo        = "CO",           # Colombia
  time       = "2025-01-01 2026-03-31",
  gprop      = "web",
  onlyInterest = TRUE
)

trends_semanal <- trends_raw$interest_over_time |>
  as_tibble() |>
  mutate(
    semana = floor_date(as.Date(date), "week", week_start = 1),
    # Google Trends devuelve "< 1" como string para valores muy bajos
    hits = ifelse(hits == "<1", 0.5, as.numeric(hits))
  ) |>
  group_by(semana) |>
  summarise(trends_index = mean(hits, na.rm = TRUE), .groups = "drop")

cat("Google Trends descargado:", nrow(trends_semanal), "semanas\n")
cat("Rango:", format(min(trends_semanal$semana)), "a", format(max(trends_semanal$semana)), "\n")


# -----------------------------------------------------------------------------
# 2. PREPARAR INVERSIÓN TRADICIONAL — Subway por canal y semana
# -----------------------------------------------------------------------------
RUTA_TRAD <- "BASE_COMPETENCIA_SUBWAY.xlsx"

raw_trad <- read_excel(RUTA_TRAD, sheet = "Consulta Infoanalisis")

# Nombres limpios para columnas con espacios o caracteres especiales
raw_trad <- raw_trad |>
  rename(inv_total = `Inv Total`)

subway_trad <- raw_trad |>
  filter(toupper(Marca) == "SUBWAY") |>
  mutate(
    fecha  = ymd(FECHA),
    semana = floor_date(fecha, "week", week_start = 1),
    # Limpiar nombre del medio para usarlo como nombre de columna
    canal  = Medio |>
      str_to_lower() |>
      str_replace_all("[^a-z0-9]+", "_") |>
      str_remove("_$")
  ) |>
  group_by(semana, canal) |>
  summarise(inversion = sum(inv_total, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(
    names_from  = canal,
    values_from = inversion,
    values_fill = 0,
    names_prefix = "trad_"
  )

cat("Canales tradicionales de Subway:\n")
print(names(subway_trad)[-1])


# -----------------------------------------------------------------------------
# 3. PREPARAR INVERSIÓN DIGITAL — Subway por canal y semana
# -----------------------------------------------------------------------------
RUTA_DIG <- "BASE_DIGITAL_SUBWAY_COMPETENCIA.xlsx"

raw_dig <- read_excel(RUTA_DIG, sheet = "BASE", skip = 3) |>
  # La fila 1 (después del skip) tiene los encabezados reales
  setNames(c("fecha","mes","medio","categorizacion","tipo_ingreso","tipo_aviso",
             "producto","version","marca","marcas","anunciante","subsector",
             "sector","categoria","prints","inversion","inv_local","scroll","advertisement")) |>
  slice(-1)  # eliminar la fila de encabezados repetida

subway_dig <- raw_dig |>
  filter(toupper(marcas) == "SUBWAY") |>
  mutate(
    fecha     = dmy(fecha),
    semana    = floor_date(fecha, "week", week_start = 1),
    inv_local = as.numeric(inv_local),
    canal     = medio |>
      str_to_lower() |>
      str_replace_all("[^a-z0-9]+", "_") |>
      str_remove("_$")
  ) |>
  group_by(semana, canal) |>
  summarise(inversion = sum(inv_local, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(
    names_from  = canal,
    values_from = inversion,
    values_fill = 0,
    names_prefix = "dig_"
  )

cat("Canales digitales de Subway:\n")
print(names(subway_dig)[-1])


# -----------------------------------------------------------------------------
# 4. PREPARAR INVERSIÓN DE COMPETENCIA — variable de control
# -----------------------------------------------------------------------------
competencia_trad <- raw_trad |>
  filter(toupper(Marca) != "SUBWAY") |>
  mutate(
    fecha  = ymd(FECHA),
    semana = floor_date(fecha, "week", week_start = 1)
  ) |>
  group_by(semana) |>
  summarise(comp_inversion_trad = sum(inv_total, na.rm = TRUE), .groups = "drop")

competencia_dig <- raw_dig |>
  filter(toupper(marcas) != "SUBWAY") |>
  mutate(
    fecha     = dmy(fecha),
    semana    = floor_date(fecha, "week", week_start = 1),
    inv_local = as.numeric(inv_local)
  ) |>
  group_by(semana) |>
  summarise(comp_inversion_dig = sum(inv_local, na.rm = TRUE), .groups = "drop")


# -----------------------------------------------------------------------------
# 5. UNIR TODO EN UN ÚNICO DATAFRAME SEMANAL
# -----------------------------------------------------------------------------
df_mmm <- trends_semanal |>
  left_join(subway_trad,       by = "semana") |>
  left_join(subway_dig,        by = "semana") |>
  left_join(competencia_trad,  by = "semana") |>
  left_join(competencia_dig,   by = "semana") |>
  # Rellenar NA con 0 en columnas de inversión
  mutate(across(-c(semana, trends_index), ~replace_na(.x, 0))) |>
  # Ordenar cronológicamente
  arrange(semana) |>
  # Eliminar semanas sin dato de Trends (pueden aparecer al inicio/fin)
  filter(!is.na(trends_index))

cat("\nDataset final para MMM:\n")
glimpse(df_mmm)
cat("Semanas totales:", nrow(df_mmm), "\n")


# -----------------------------------------------------------------------------
# 6. IDENTIFICAR COLUMNAS DE MEDIOS (dinámico)
# -----------------------------------------------------------------------------
# Canales pagos: todo lo que empieza con "trad_" o "dig_"
paid_media_cols <- names(df_mmm) |>
  keep(~str_starts(.x, "trad_") | str_starts(.x, "dig_"))

# Variables orgánicas (competencia)
organic_cols <- c("comp_inversion_trad", "comp_inversion_dig")
# Filtrar solo los que existen en el df
organic_cols <- intersect(organic_cols, names(df_mmm))

cat("\nVariables paid media:", paid_media_cols, "\n")
cat("Variables orgánicas:", organic_cols, "\n")


# -----------------------------------------------------------------------------
# 7. ROBYN — InputCollect
# -----------------------------------------------------------------------------
# Generar hiperparámetros automáticamente para cada canal
# Rango: alpha (forma curva sat.), gamma (punto inflexión), theta (decaimiento adstock)
build_hyperparams <- function(channels, adstock_type = "geometric") {
  params <- list()
  for (ch in channels) {
    params[[paste0(ch, "_alphas")]] <- c(0.5, 3.0)
    params[[paste0(ch, "_gammas")]] <- c(0.3, 1.0)
    if (adstock_type == "geometric") {
      # Theta: TV/OOH tienen memorias más largas que digital
      if (str_detect(ch, "tv|television|exterior|ooh")) {
        params[[paste0(ch, "_thetas")]] <- c(0.1, 0.7)
      } else if (str_detect(ch, "radio")) {
        params[[paste0(ch, "_thetas")]] <- c(0.0, 0.5)
      } else {
        params[[paste0(ch, "_thetas")]] <- c(0.0, 0.3)  # digital: efecto rápido
      }
    }
  }
  params[["train_size"]] <- c(0.5, 0.8)
  return(params)
}

hyperparams <- build_hyperparams(paid_media_cols, adstock_type = "geometric")

InputCollect <- robyn_inputs(
  dt_input        = df_mmm,
  dt_holidays     = dt_prophet_holidays,  # festivos incluidos en Robyn

  # Variable dependiente (Google Trends como proxy de demanda)
  dep_var         = "trends_index",
  dep_var_type    = "revenue",    # tratamos el índice como métrica continua

  # Tiempo
  date_var        = "semana",
  intervalType    = "week",

  # País para Prophet (festivos)
  prophet_country = "CO",
  prophet_vars    = c("trend", "season", "holiday"),  # componentes temporales

  # Medios pagos
  paid_media_spends = paid_media_cols,
  paid_media_vars   = paid_media_cols,  # en este caso spend = variable (no tenemos impresiones separadas)

  # Variables orgánicas / control
  organic_vars    = organic_cols,

  # Adstock
  adstock         = "geometric",

  # Hiperparámetros
  hyperparameters = hyperparams,

  # Ventana de calibración (si tuvieras lift tests o MMM externos)
  # calibration_input = NULL  # dejar en NULL si no hay
)

# Graficar correlaciones y estadísticas descriptivas
robyn_corr <- robyn_inputs(InputCollect, quiet = TRUE)


# -----------------------------------------------------------------------------
# 8. ROBYN — Entrenar modelos
# -----------------------------------------------------------------------------
OutputModels <- robyn_run(
  InputCollect = InputCollect,
  cores        = 4,          # ajustar según CPU disponible
  iterations   = 2000,       # mínimo recomendado
  trials       = 5,          # corridas independientes del optimizador
  ts_validation = TRUE       # reserva ~20% de semanas para validación
)

# Ver métricas de convergencia
print(OutputModels)


# -----------------------------------------------------------------------------
# 9. ROBYN — Seleccionar mejores modelos (Pareto)
# -----------------------------------------------------------------------------
OutputSelect <- robyn_outputs(
  InputCollect  = InputCollect,
  OutputModels  = OutputModels,
  pareto_fronts = "auto",           # selección automática de frentes de Pareto
  clusters      = TRUE,             # agrupa modelos similares para facilitar elección
  csv_out       = "pareto",
  plot_folder   = "./resultados_mmm_subway/",
  plot_pareto   = TRUE
)

# Revisar los modelos del primer frente de Pareto
cat("\nModelos seleccionados:\n")
print(OutputSelect$allSolutions)


# -----------------------------------------------------------------------------
# 10. ROBYN — Seleccionar modelo final y asignar presupuesto
# -----------------------------------------------------------------------------
# ⚠ Reemplaza "XXXXXX_X" con el ID del modelo que elijas del gráfico de Pareto
# Criterio: bajo NRMSE + bajo MAPE + decomp.RSSD cercano a 0
SELECT_MODEL <- OutputSelect$allSolutions[1]  # primer modelo como ejemplo

# Visualizar el modelo seleccionado
robyn_onepagers(
  InputCollect  = InputCollect,
  OutputCollect = OutputSelect,
  select_model  = SELECT_MODEL,
  export        = TRUE
)

# Optimizador de presupuesto
# Ajusta total_budget al presupuesto semanal promedio de Subway en COP
presupuesto_semanal_cop <- df_mmm |>
  select(all_of(paid_media_cols)) |>
  summarise(across(everything(), sum)) |>
  pivot_longer(everything()) |>
  summarise(total = sum(value)) |>
  pull(total) / nrow(df_mmm)

cat("\nPresupuesto semanal promedio histórico (COP):", scales::comma(presupuesto_semanal_cop), "\n")

AllocatorCollect <- robyn_allocator(
  InputCollect  = InputCollect,
  OutputCollect = OutputSelect,
  select_model  = SELECT_MODEL,
  scenario      = "max_response",      # maximizar demanda (Trends) dado el presupuesto
  total_budget  = presupuesto_semanal_cop,
  date_range    = "last_4",            # últimas 4 semanas como línea base
  export        = TRUE,
  plot_folder   = "./resultados_mmm_subway/"
)

# Ver recomendación de asignación por canal
print(AllocatorCollect$dt_optimOut)


# -----------------------------------------------------------------------------
# 11. GUARDAR MODELO PARA USO FUTURO
# -----------------------------------------------------------------------------
robyn_save(
  robyn_object  = "./resultados_mmm_subway/robyn_model.RDS",
  select_model  = SELECT_MODEL,
  InputCollect  = InputCollect,
  OutputCollect = OutputSelect
)

cat("\n✓ Modelo guardado en ./resultados_mmm_subway/robyn_model.RDS\n")
cat("✓ Gráficos exportados en ./resultados_mmm_subway/\n")

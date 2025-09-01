################################################################################
# ~ Cleaning and standardising geographic names in R with `prep_geon full code ~
################################################################################

### Step 1: Install packages ---------------------------------------------------

# 1) install pak
install.packages("pak")

# 2) install packages
pak::pkg_install(
  c(
    "dplyr",        # data manipulation
    "here",         # for relative file paths
    "ggplot2",      # plotting
    "cli",          # console alerts/messages
    "grid",         # unit sizing for plot theme elements
    "ahadi-analytics/sntutils" # for prep_geoname and other helpers
  ),
  dependencies = TRUE
)

### Step 2: Load data ----------------------------------------------------------

# import data
nga_dhs <- sntutils::read(
  here::here("01_data/dhs/Admin2_NGDHS2018Table.xlsx")
) |>
  dplyr::select(
    adm0 = adm0_name,
    adm1 = adm1_name,
    adm2 = adm2_name,
    pop_no_basic_water_value = nobaswatv, # % without basic water
    pop_no_basic_water_ci_lower = nobaswatl, # % without basic water lower CI
    pop_no_basic_water_ci_upper = nobaswatu # % without basic water upper CI
  )

# check the data
dplyr::glimpse(nga_dhs)

### Step 2: Load data ----------------------------------------------------------

# get/load NGA shapefile (WHO)
nga_shp <- sntutils::download_shapefile(
  country_codes = "NGA",
  admin_level = "adm2",
  dest_path = here::here("01_data/shapefile")
)

# check shapefile
dplyr::glimpse(nga_shp)

### Step 3: Check matches ------------------------------------------------------

# check matches
sntutils::calculate_match_stats(
  nga_dhs,
  lookup_data = nga_shp,
  level0 = "adm0",
  level1 = "adm1",
  level2 = "adm2"
)

### Step 4: Start matching -----------------------------------------------------

#### Step 4.1: Use the shapefile as the reference ------------------------------

# path to cache
cache_path <- here::here("01_data/cache/geoname_cleaning_nga_new.rds")
unmatched_path <- here::here("01_data/cache/nga_unmatched_adm2.rds")

# 2) Run interactive, hierarchy-based matching
nga_dhs_cleaned <- sntutils::prep_geonames(
  target_df = nga_dhs,   # data to be harmonised
  lookup_df = nga_shp,   # authoritative reference
  level0 = "adm0",
  level1 = "adm1",
  level2 = "adm2",
  cache_path = cache_path,
  interactive = TRUE
)

### Step 4: Start matching -----------------------------------------------------

#### Step 4.3: Verify the final join with the shapefile ------------------------

# 1) Recompute match statistics
sntutils::calculate_match_stats(
  nga_dhs_cleaned,
  lookup_data = nga_shp,
  level0 = "adm0",
  level1 = "adm1",
  level2 = "adm2"
)

# 2) Explicit unmatched check via anti-join
unmatched_after <- dplyr::anti_join(
  dplyr::distinct(nga_dhs_cleaned, adm0, adm1, adm2),
  dplyr::distinct(nga_shp, adm0, adm1, adm2),
  by = c("adm0", "adm1", "adm2")
)

if (nrow(unmatched_after) == 0) {
  cli::cli_alert_success(
    "All admin units in the target now match the shapefile."
  )
} else {
  cli::cli_alert_warning(
    paste0(nrow(unmatched_after), " admin units still need attention.")
  )
  unmatched_after
}

### Step 4: Start matching -----------------------------------------------------

#### Step 4.4: Review and inspect the cache ------------------------------------

# get cache file
cache_df <- readRDS(cache_path)

# print cache
print(cache_df)

### Step 5: Edge case — fix parent level before matching -----------------------

# import edge case data
nga_dhs_edge <- sntutils::read(
  here::here("01_data/dhs/Admin2_NGDHS2018Table_edge.xlsx")
) |>
  dplyr::select(
    adm0 = adm0_name,
    adm1 = adm1_name,
    adm2 = adm2_name,
    pop_no_basic_water_value = nobaswatv, # % without basic water
    pop_no_basic_water_ci_lower = nobaswatl, # % without basic water lower CI
    pop_no_basic_water_ci_upper = nobaswatu # % without basic water upper CI
  )

# check the matching of the stats of the edge case data
sntutils::calculate_match_stats(
  nga_dhs_edge,
  lookup_data = nga_shp,
  level0 = "adm0",
  level1 = "adm1",
  level2 = "adm2"
)

### Step 5: Edge case — fix parent level before matching -----------------------

# 1) set up path to save the unmatched admin names
unmatched_path <- here::here("01_data/cache/nga_unmatched_adm2.rds")

# 2) run interactive, hierarchy-based matching
nga_dhs_edge_cleaned <- sntutils::prep_geonames(
  target_df = nga_dhs_edge, # data to be harmonised
  lookup_df = nga_shp, # authoritative reference
  level0 = "adm0",
  level1 = "adm1",
  level2 = "adm2",
  cache_path = cache_path,
  unmatched_export_path = unmatched_path,
  interactive = FALSE
)

### Step 5: Edge case — fix parent level before matching -----------------------

# get cache file
unmatched_df <- readRDS(unmatched_path)

# print cache
print(unmatched_df)

### Step 5: Edge case — fix parent level before matching -----------------------

# get names of non‑matched adm2
nonmatched_adm2 <- c(
  "ETHIOPE WEST",
  "IKA NORTH EAST",
  "IKA SOUTH",
  "IKEDURU",
  "ISIALA MBANO",
  "MBATOLI",
  "NGOR-OKPALA"
)

nga_shp |>
  dplyr::filter(adm2 %in% nonmatched_adm2) |>
  dplyr::distinct(adm1, adm2)

### Step 5: Edge case — fix parent level before matching -----------------------

# define sets of adm2 that belong to specific adm1
delta_adm2 <- c(
  "ETHIOPE WEST",
  "IKA NORTH EAST",
  "IKA SOUTH"
)

imo_adm2 <- c(
  "IKEDURU",
  "ISIALA MBANO",
  "MBATOLI",
  "NGOR-OKPALA"
)

# 1) fix parent (adm1) misassignments reproducibly
nga_dhs_edge_fixed <- nga_dhs_edge_cleaned |>
  dplyr::mutate(
    adm1 = dplyr::case_when(
      adm2 %in% delta_adm2 ~ "DELTA",
      adm2 %in% imo_adm2 ~ "IMO",
      TRUE ~ adm1
    )
  )

# 2) re-run matching using the cache (non-interactive)
nga_dhs_edge_cleaned <- sntutils::prep_geonames(
  target_df = nga_dhs_edge_fixed,
  lookup_df = nga_shp,
  level0 = "adm0",
  level1 = "adm1",
  level2 = "adm2",
  cache_path = cache_path,
  interactive = FALSE
)

### Step 6: Validate with a map (join to shapefile) ----------------------------

# 1) join cleaned data to shapefile at adm2
nga_map <- nga_shp |>
  dplyr::left_join(
    nga_dhs_edge_cleaned |>
      dplyr::select(adm0, adm1, adm2, pop_no_basic_water_value),
    by = c("adm0", "adm1", "adm2")
  )

# 2) quick NA check on the indicator
n_na <- sum(is.na(nga_map$pop_no_basic_water_value))
cli::cli_alert_info(
  paste0(n_na, " polygons have no indicator value (NA).")
)

# 3) plot map
p <- ggplot2::ggplot(nga_map) +
  ggplot2::geom_sf(
    ggplot2::aes(fill = pop_no_basic_water_value),
    color = NA,
    linewidth = 0
  ) +
  ggplot2::scale_fill_viridis_c(
    option = "A",
    direction = -1,
    name = "% without basic water"
  ) +
  ggplot2::labs(
    title = "Nigeria: Population without basic water (DHS 2018, adm2)",
    subtitle = "Joined using cleaned names (`nga_dhs_edge_cleaned`)",
    caption = "Source: DHS Local Data Mapping Tool; WHO ADM2 boundaries"
  ) +
  ggplot2::theme_void() +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold"),
    legend.position = "bottom",
    legend.title.position = "top",
    legend.key.width = grid::unit(1, "cm"),
    legend.justification = c(0, 0)
  )

# save plot
ggplot2::ggsave(
  plot = p,
  filename = "03_outputs/validation_map.png"
)

# check plot
print(p)

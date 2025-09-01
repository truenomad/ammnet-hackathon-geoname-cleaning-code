**Overview**

- **Goal:** Clean and standardise `adm0/adm1/adm2` names so indicators join to authoritative boundaries.
- **Method:** `sntutils::prep_geonames` + cached decisions, edge‑case fixes, and map validation.

**Quick Start**

- **Open project:** Start R/RStudio at repo root so `here::here()` paths work.
- **Install deps:** `install.packages("pak"); pak::pkg_install(c("dplyr","here","ggplot2","cli","grid","ahadi-analytics/sntutils"), dependencies = TRUE)`
- **Run script:** `02_scripts/geographic-name-cleaning-training.R:1` (first pass interactive), then optional batch: `Rscript 02_scripts/geographic-name-cleaning-training.R`.

**Pipeline**

- **Load inputs:** DHS‑style table + WHO ADM2 shapefile for `NGA`.
- **Assess matches:** `sntutils::calculate_match_stats(...)` by admin level.
- **Harmonise:** `sntutils::prep_geonames(...)` (writes cache `01_data/cache/geoname_cleaning_nga_new.rds`).
- **Edge cases:** Review `01_data/cache/nga_unmatched_adm2.rds`; fix parent `adm1`, re‑run.
- **Validate:** Join to shapefile; save `03_outputs/validation_map.png`.

**Key Files**

- `02_scripts/geographic-name-cleaning-training.R:1`: End‑to‑end workflow.
- `01_data/dhs/Admin2_NGDHS2018Table.xlsx:1`: Example input with `adm*_name` columns.
- `01_data/shapefile/who_shapefile_nga_adm2_latest.gpkg:1`: Reference boundaries (auto‑downloaded).
- `01_data/cache/*.rds:1`: Cache and unmatched outputs.

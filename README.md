# UK Housing Affordability: A Decade of Regional Divergence (2015–2025)

> Analysing 10+ years of HM Land Registry transactions and ONS earnings data to map where home ownership has moved furthest out of reach — and why.

![SQL](https://img.shields.io/badge/SQL-MySQL-336791)
![Excel](https://img.shields.io/badge/Excel-Power%20Query-217346)
![Tableau](https://img.shields.io/badge/Tableau-Public-E97627)
![Licence](https://img.shields.io/badge/Data-OGL%20v3.0-green)

<!-- Replace the badges above with your actual stack (e.g. SQL Server if you used T-SQL). Generate more at shields.io -->

---

## Overview

**The question:** Over the last decade, which parts of the UK have become the least affordable to buy in, and is the squeeze driven more by rising prices or by earnings failing to keep up?

This project combines transaction-level sale prices with regional earnings to build a reproducible affordability picture across UK regions and local authorities. It demonstrates an end-to-end analytics workflow: sourcing official open data, loading and cleaning several million records in SQL, preparing reference data and validating results in Excel, and communicating insight through an interactive Tableau dashboard.

## Key findings

<!-- THIS IS THE MOST IMPORTANT SECTION. Replace with YOUR real numbers once analysis is done. Lead with the number. -->

- 🔺 **[London / region] remained least affordable** at **[X.X]× median earnings** in 2025, vs a national figure of **[X.X]×**.
- 📈 Median prices rose **[XX]%** over the decade while median earnings rose only **[XX]%**, widening the gap most in **[region]**.
- 🗺️ The **North–South affordability divide narrowed/widened**: [one-sentence finding].
- 🏘️ **[Property type / flats vs detached]** showed the sharpest change in **[area]**.

## Live dashboard

🔗 **[Explore the interactive Tableau dashboard »](https://public.tableau.com/your-link-here)**

## Data sources

All data is official UK open data published under the Open Government Licence v3.0.

| Source | What it provides | Granularity | Link |
|---|---|---|---|
| HM Land Registry — Price Paid Data | Every residential sale in England & Wales, 1995–present | Transaction level | [gov.uk](https://www.gov.uk/government/statistical-data-sets/price-paid-data-downloads) |
| UK House Price Index (HPI) | Modelled house price index & average prices | Region / local authority, monthly | [gov.uk](https://landregistry.data.gov.uk/app/ukhpi) |
| ONS — House price to earnings ratio | Affordability ratios (price ÷ gross annual earnings) | Local authority, annual | [ons.gov.uk](https://www.ons.gov.uk/peoplepopulationandcommunity/housing/datasets/ratioofhousepricetoworkplacebasedearningslowerquartileandmedian) |
| ONS — National Statistics Postcode Lookup (NSPL) | Maps postcodes to regions / local authorities | Postcode | [ONS Geoportal](https://geoportal.statistics.gov.uk/) |

> **Attribution:** Contains HM Land Registry data © Crown copyright and database right 2026. This data is licensed under the Open Government Licence v3.0. Contains public sector information from the Office for National Statistics licensed under the same.

## Methodology

**Pipeline:** `raw CSVs → SQL (load, clean, aggregate) → Excel / Power Query (reference data + validation) → Tableau`

Key decisions (full SQL in `sql/`, Excel prep in `excel/`):

**In SQL** (on the multi-million-row transaction data):
- Loaded the headerless Land Registry yearly files via bulk load (`LOAD DATA INFILE`) and applied a defined schema with correct data types.
- Restricted to **standard price-paid transactions** (PPD category `A`) to exclude repossessions and non-market sales, and dropped records flagged for deletion.
- Removed null/invalid postcodes before any geographic aggregation.
- Flagged (not silently deleted) extreme outliers — £0/£1 transfers and the top 0.1% of values, which are typically bulk or non-arm's-length sales.
- Joined postcodes to regions and local authorities via the ONS NSPL lookup.
- Aggregated using the **median, not the mean**, because house prices are heavily right-skewed — this matches the ONS methodology. (MySQL 8.0 has no median function, so it is computed with a `ROW_NUMBER()` / `COUNT()` window-function approach.)

**In Excel (Power Query):**
- Cleaned the ONS affordability and NSPL downloads — removed header/footer junk, unpivoted wide year columns into tidy long format, standardised local-authority names for clean joins.
- Built a PivotTable workbook to independently validate the SQL median aggregates against a sample.

## Repository structure

```
uk-housing-affordability/
├── README.md
├── LICENSE
├── .gitignore                 # excludes large raw data files
├── data/
│   ├── raw/                   # downloaded source files (gitignored)
│   └── processed/             # cleaned extracts exported for Tableau
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_load_data.sql
│   ├── 03_clean_transform.sql
│   └── 04_analysis_queries.sql
├── excel/
│   ├── data_prep.xlsx         # Power Query ETL for reference data
│   └── validation.xlsx        # PivotTable checks against SQL output
├── tableau/
│   └── dashboard_link.md      # link + notes on the published dashboard
└── images/
    └── dashboard_preview.png
```

## How to reproduce

```bash
# 1. Download source data (instructions in data/raw/README.md)
#    - Land Registry yearly files (2015 onward)
#    - ONS affordability ratio dataset
#    - ONS NSPL postcode lookup

# 2. Create the schema and bulk-load the raw transactions
mysql -u root -p housing < sql/01_create_tables.sql
mysql -u root -p housing < sql/02_load_data.sql        # uses LOAD DATA INFILE

# 3. Clean, transform and aggregate to medians by region/LA/year
mysql -u root -p housing < sql/03_clean_transform.sql
mysql -u root -p housing < sql/04_analysis_queries.sql

# 4. Prepare reference data and validate in Excel
#    open excel/data_prep.xlsx   (Power Query: clean + unpivot ONS files)
#    open excel/validation.xlsx  (PivotTables: spot-check SQL medians)

# 5. Build the dashboard
#    connect Tableau to the database (or the processed extract) and publish to Tableau Public
```

> Note: the Land Registry single file is ~5 GB and is **not** committed to the repo. Use the yearly files (115–230 MB each) for a lighter setup; large files are excluded via `.gitignore`.

## Tools & technologies

`SQL` (MySQL — load, clean, aggregate) · `Excel` (Power Query ETL, PivotTable validation) · `Tableau Public` · `Git`

## Limitations & next steps

- Price Paid Data covers **England & Wales only**; Scotland and Northern Ireland use separate registers (a natural v2 extension via Registers of Scotland).
- The two most recent months of Land Registry data are incomplete due to registration lag.
- Affordability uses workplace-based earnings, which differ from residence-based earnings — both are available and could be compared.
- **Next:** add a rental affordability layer using the ONS Price Index of Private Rents.

## Licence

Code in this repository is released under the MIT Licence. Data is © Crown copyright, used under the Open Government Licence v3.0.

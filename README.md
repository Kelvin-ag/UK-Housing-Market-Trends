# UK Regional Housing Affordability, 2015–2025

An end-to-end analysis of how housing affordability changed across the nine English
regions over a decade, and whether the change was driven by **rising prices** or
**stagnant earnings**. Built on 11.1 million individual property transactions joined
to official earnings data, using a layered SQL pipeline and visualised in Tableau.

![SQL](https://img.shields.io/badge/SQL-MySQL-336791)
![Excel](https://img.shields.io/badge/Excel-Power%20Query-217346)
![Tableau](https://img.shields.io/badge/Tableau-Public-E97627)
![Licence](https://img.shields.io/badge/Data-OGL%20v3.0-green)

![Dashboard preview](/Users/kelvinagara/Desktop/Project Files/UK-Housing-Market-Trends/img/Screenshot 2026-06-14 at 21.41.34.png)
---

## Headline findings

Affordability (median house price ÷ median gross annual earnings) **worsened in 7 of
the 9 English regions** between 2015 and 2025. The driver was **prices, not stagnant
earnings**. Earnings grew a healthy 35–46% across every region, but in most regions
house prices grew faster still.

| Region | Price change | Earnings change | Affordability ratio (2015 → 2025) | Change |
|---|---|---|---|---|
| East Midlands | +56.3% | +42.4% | 6.28 → 7.02 | **+0.74** |
| East of England | +47.1% | +41.4% | 8.42 → 9.02 | +0.60 |
| West Midlands | +54.2% | +44.3% | 6.27 → 6.80 | +0.53 |
| South East | +40.5% | +37.7% | 9.13 → 9.58 | +0.45 |
| North West | +55.2% | +45.6% | 5.55 → 5.92 | +0.37 |
| Yorkshire & The Humber | +48.3% | +41.6% | 5.68 → 6.03 | +0.35 |
| South West | +43.5% | +43.3% | 8.17 → 8.33 | +0.16 |
| North East | +29.7% | +35.7% | 5.15 → 5.00 | −0.15 |
| London | +32.0% | +40.8% | 11.05 → 10.61 | −0.44 |

*Higher ratio = less affordable. A positive change means affordability worsened.*

Three takeaways:

1. **The Midlands were the affordability losers.** East Midlands, West Midlands and
   East of England saw affordability deteriorate most, as prices ran 12–14 points ahead
   of earnings growth.
2. **Only London and the North East improved**, and for the same underlying reason in
   reverse: in both, earnings grew faster than their comparatively slow price growth.
3. **The cheaper regions had the hottest price growth.** The North West, East Midlands
   and West Midlands (all sub-£165k in 2015) saw the largest price surges (+54–56%),
   while London grew slowest (+32%), a partial price convergence, though absolute
   levels remain far apart (London £528k vs North East £172k in 2025).

---

## The question

> *Which English regions became least affordable over 2015–2025, and was the change
> driven by rising prices or by earnings failing to keep pace?*

A single affordability ratio answers "how affordable," but not "why." Decomposing the
ratio into its price and earnings components per region is what turns a number into an
explanation.

---

## Live dashboard

🔗 **[Explore the interactive Tableau dashboard »](https://public.tableau.com/app/profile/mozi.agara/viz/UKRegionalHousingAffordability2015to2025_/Dashboard1)**

## Data sources

| Source | Used for | Notes | Link |
|---|---|---|---|
| HM Land Registry: Price Paid Data (2015–2025) | Every residential sale; basis for region-level median price | ~11.1M rows; England & Wales | [gov.uk](https://www.gov.uk/government/statistical-data-sets/price-paid-data-downloads) |
| ONS: National Statistics Postcode Lookup (NSPL) | Maps each postcode to its E12 region code | Region field is England-only | [ONS Geoportal](https://geoportal.statistics.gov.uk/) |
| ONS: House price to workplace-based earnings ratio (tables 1a/1b/1c) | Median earnings and the published affordability ratio | Region grain, 1997–2025 | [ons.gov.uk](https://www.ons.gov.uk/peoplepopulationandcommunity/housing/datasets/ratioofhousepricetoworkplacebasedearningslowerquartileandmedian) |

All sources are open data. Earnings (table 1b) is the dimension that **cannot** be
derived from transaction data; it is what makes the prices-vs-earnings split possible.

---

## Method

A layered pipeline, each stage materialised so it can be inspected before the next is
built (`raw → clean → flagged → summary → analysis`):

1. **Raw load.** All 11 years of Price Paid loaded into `pp_raw` (11,097,426 rows). A
   `sale_year` column is derived from the transfer date via a `GENERATED ALWAYS AS …
   STORED` column, then indexed.
2. **Reference data.** NSPL loaded into `postcode_region` (postcode → E12 region,
   filtered to the nine English regions). ONS price/earnings/ratio cleaned in Power
   Query and loaded into `affordability_ref` (99 rows: 9 regions × 11 years).
3. **Clean layer.** `pp_clean` joins region onto each sale and applies the scoping
   decisions below. **11.1M → 8.9M rows.**
4. **Outlier flagging.** `pp_flagged` adds an `is_outlier` flag using `PERCENT_RANK()`
   *within each region-year*, marking the top and bottom 1% of prices (2.03% of rows).
   Nothing is deleted; the flag lets analysis run on the clean core while keeping the
   full distribution available.
5. **Summary.** `housing_summary_region` computes the **median** price per region-year
   (MySQL 8.0 has no `MEDIAN()`, so a `ROW_NUMBER()`/`COUNT()` window pattern is used),
   collapsing 8.9M rows to 99.
6. **Analysis views.** `v_region_analysis` joins price, earnings and ratio together;
   `v_region_index` rebases every series to **2015 = 100** so regions of very different
   absolute scale (London vs North East) become directly comparable on one chart.

### Key analytical decisions

- **England, nine regions only.** Welsh postcodes map to a placeholder region code in
  the NSPL, so Wales is out of scope; this keeps the postcode→region join and the ONS
  region join on a single consistent key.
- **Homes only** (`property_type <> 'O'`): excludes offices, car parks and land.
- **Standard market sales only** (`ppd_category = 'A'`): excludes repossessions and
  bulk/non-market transfers, so medians reflect genuine market value.
- **Median over mean.** Median is robust to the long upper tail of property prices; mean
  is retained alongside it as a comparison (the mean vs median gap is itself a signal).
- **Base-year indexing.** Raw price charts let London's scale visually flatten faster-
  growing smaller regions; indexing to 2015 corrects this and reveals the true growth
  rates.

---

## Repository structure

```
.
├── sql/
│   ├── 01_setup_and_raw_load.sql      # database, pp_raw, sale_year column, index
│   ├── 02_load_postcode_region.sql    # NSPL load, filtered to E12 regions
│   ├── 03_load_affordability.sql      # ONS 1a/1b/1c -> affordability_ref
│   ├── 04_build_clean.sql             # pp_clean: region join + scoping filters
│   ├── 05_flag_outliers.sql           # pp_flagged: PERCENT_RANK outlier flag
│   ├── 06_summary_region.sql          # housing_summary_region: median per region-year
│   ├── 07_analysis_views.sql          # v_region_analysis (price + earnings + ratio)
│   └── 08_price_index.sql             # v_region_index: 2015=100 indexed series
└── README.md
```

---

## Reproducing the analysis

1. **Download the sources** (links in [Data sources](#data-sources)) into a local
   `data/` folder. Price Paid is published as annual CSVs (2015 split into two parts);
   the NSPL ships as postcode-area CSVs.
2. **Enable local file loading** in MySQL: `SET GLOBAL local_infile = 1;` and add
   `OPT_LOCAL_INFILE=1` to the Workbench connection's *Advanced* options.
3. **Run the SQL files in order.** The raw load and the clean/flag/summary builds are
   heavy operations on large tables, so raise the Workbench read timeout (SQL Editor
   preferences) to ~600s and let them complete server-side rather than re-running.
4. **Clean the ONS workbook in Power Query.** For tables 1a/1b/1c: remove the title
   row, promote headers, filter to `E12` region codes, keep `Code`/`Name`/`2015–2025`
   (drops the trailing 5-Year Average), then unpivot the year columns to tidy format.
5. **Connect Tableau** to the two analysis views (or to CSV exports of them, only 99
   rows each) and build the indexed-trend and price-vs-earnings dashboards.

---

## Results at a glance

- **11,097,426** transactions processed → **8,939,813** standard residential sales after
  cleaning and scoping.
- **9 regions × 11 years** of median price, median earnings and affordability ratio.
- Region-level medians cross-checked against ONS published figures (agreement within
  ~2%).

---
## Licence

Code in this repository is released under the MIT Licence. Data is © Crown copyright, used under the Open Government Licence v3.0.

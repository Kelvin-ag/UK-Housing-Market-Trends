-- =====================================================================
-- 07_analysis_views.sql
-- Join the computed price summary to the ONS reference data, producing
-- the single view the analysis reads from: computed median price, ONS
-- median price (cross-check), median earnings and the affordability
-- ratio, per region-year. Region names are reattached here from
-- affordability_ref rather than carried through the large tables.
-- Input:  housing_summary_region, affordability_ref
-- Output: v_region_analysis  (99 rows)
-- =====================================================================

USE housing;

CREATE VIEW v_region_analysis AS
SELECT
    h.region_code,
    a.region_name,
    h.sale_year,
    h.sales_count,
    h.median_price  AS median_price_computed,   -- from 8.9M transactions
    a.median_price  AS median_price_ons,         -- ONS 1a, validation cross-check
    a.median_earnings,
    a.ratio         AS affordability_ratio
FROM housing_summary_region h
JOIN affordability_ref a
    ON h.region_code = a.region_code
   AND h.sale_year   = a.sale_year;

-- Validation
SELECT COUNT(*) FROM v_region_analysis;                          -- expect 99
SELECT region_name, sale_year,
       median_price_computed, median_price_ons,
       median_earnings, affordability_ratio
FROM v_region_analysis
WHERE region_code IN ('E12000007', 'E12000001')
  AND sale_year IN (2015, 2025)
ORDER BY region_code, sale_year;

-- ---------------------------------------------------------------------
-- Decade comparison: per-region change in price, earnings and ratio,
-- 2015 vs 2025. Self-join on region_code across the two endpoint years.
-- ratio_change > 0 means affordability worsened; sorting descending
-- ranks the least-affordable-becoming regions first.
-- (Exported to CSV to drive the Tableau diverging-bar chart.)
-- ---------------------------------------------------------------------
SELECT
    a.region_name,
    a.median_price_computed AS price_2015,
    b.median_price_computed AS price_2025,
    ROUND((b.median_price_computed / a.median_price_computed - 1) * 100, 1) AS price_pct,
    a.median_earnings       AS earn_2015,
    b.median_earnings       AS earn_2025,
    ROUND((b.median_earnings / a.median_earnings - 1) * 100, 1) AS earn_pct,
    a.affordability_ratio   AS ratio_2015,
    b.affordability_ratio   AS ratio_2025,
    ROUND(b.affordability_ratio - a.affordability_ratio, 2) AS ratio_change
FROM v_region_analysis a
JOIN v_region_analysis b
    ON a.region_code = b.region_code
   AND a.sale_year = 2015
   AND b.sale_year = 2025
ORDER BY ratio_change DESC;

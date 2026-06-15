-- =====================================================================
-- 08_price_index.sql
-- Rebase median price and median earnings to 2015 = 100 for each region,
-- so regions of very different absolute scale (London vs North East)
-- become directly comparable on one chart. Raw price levels let London's
-- scale visually flatten faster-growing smaller regions; indexing shows
-- the true growth rates.
-- Input:  v_region_analysis
-- Output: v_region_index  (99 rows)
-- =====================================================================

USE housing;

-- ---------------------------------------------------------------------
-- FIRST_VALUE(... ORDER BY sale_year) returns each region's earliest
-- year (2015) value as the denominator. The default window frame starts
-- at the first row of the partition, so the base year is picked up
-- automatically without hard-coding it.
-- ---------------------------------------------------------------------
CREATE VIEW v_region_index AS
SELECT
    region_code,
    region_name,
    sale_year,
    median_price_computed AS median_price,
    ROUND(
        median_price_computed / FIRST_VALUE(median_price_computed) OVER (
            PARTITION BY region_code ORDER BY sale_year
        ) * 100, 1
    ) AS price_index,
    median_earnings,
    ROUND(
        median_earnings / FIRST_VALUE(median_earnings) OVER (
            PARTITION BY region_code ORDER BY sale_year
        ) * 100, 1
    ) AS earnings_index,
    affordability_ratio
FROM v_region_analysis;

-- Validation: every 2015 row indexes to 100.0; 2025 indices match the
-- known decade growth rates (e.g. London price 132.0, earnings 140.8).
SELECT region_name, sale_year, median_price, price_index, earnings_index
FROM v_region_index
WHERE region_code IN ('E12000007', 'E12000001')
  AND sale_year IN (2015, 2025)
ORDER BY region_code, sale_year;

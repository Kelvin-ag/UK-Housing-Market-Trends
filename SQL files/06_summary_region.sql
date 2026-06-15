-- =====================================================================
-- 06_summary_region.sql
-- Collapse the clean sales to one row per region-year, carrying the
-- median price, mean price and sales count. This is the grain used by
-- all analysis and visualisation.
-- Input:  pp_flagged (non-outlier rows only)
-- Output: housing_summary_region  (99 rows)
-- =====================================================================

USE housing;

-- ---------------------------------------------------------------------
-- MySQL 8.0 has no MEDIAN() function, so the median is built with a
-- ROW_NUMBER()/COUNT() window pattern:
--   - rank each sale within its region-year (rn), and count the group (cnt)
--   - the two FLOOR expressions select the middle row(s):
--       odd  cnt -> both point at the single middle rank
--       even cnt -> they point at the two middle ranks
--   - AVG of those one or two values is the true median either way
-- ROW_NUMBER() (not RANK) guarantees a gapless 1..cnt sequence, which
-- the middle-row arithmetic relies on.
--
-- mean_price is kept alongside the median; the gap between them is a
-- signal in itself (mean sits well above median where high-value sales
-- are common, e.g. London).
-- Heavy sort; raise the read timeout and let it complete.
-- ---------------------------------------------------------------------
CREATE TABLE housing_summary_region AS
WITH ranked AS (
    SELECT
        region_code,
        sale_year,
        price,
        ROW_NUMBER() OVER (PARTITION BY region_code, sale_year ORDER BY price) AS rn,
        COUNT(*)     OVER (PARTITION BY region_code, sale_year) AS cnt
    FROM pp_flagged
    WHERE is_outlier = 0
),
medians AS (
    SELECT region_code, sale_year, ROUND(AVG(price)) AS median_price
    FROM ranked
    WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2))
    GROUP BY region_code, sale_year
),
aggs AS (
    SELECT
        region_code,
        sale_year,
        COUNT(*)          AS sales_count,
        ROUND(AVG(price)) AS mean_price
    FROM pp_flagged
    WHERE is_outlier = 0
    GROUP BY region_code, sale_year
)
SELECT
    a.region_code,
    a.sale_year,
    a.sales_count,
    m.median_price,
    a.mean_price
FROM aggs a
JOIN medians m
  ON a.region_code = m.region_code
 AND a.sale_year   = m.sale_year;

-- Validation
SELECT COUNT(*) FROM housing_summary_region;                     -- expect 99
SELECT region_code, sale_year, median_price, sales_count         -- decade endpoints
FROM housing_summary_region
WHERE region_code IN ('E12000007', 'E12000001')                 -- London, North East
  AND sale_year IN (2015, 2025)
ORDER BY region_code, sale_year;

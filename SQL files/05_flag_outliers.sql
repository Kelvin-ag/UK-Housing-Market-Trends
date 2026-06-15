-- =====================================================================
-- 05_flag_outliers.sql
-- Flag extreme prices within each region-year so a handful of very high
-- or very low sales cannot distort downstream statistics.
-- Input:  pp_clean
-- Output: pp_flagged  (same rows as pp_clean, plus is_outlier flag)
-- =====================================================================

USE housing;

-- ---------------------------------------------------------------------
-- PERCENT_RANK() ranks each sale by price WITHIN its own region-year,
-- so the threshold is local: a price that is extreme in the North East
-- is judged against the North East, not against London. Sales in the
-- bottom 1% (pr < 0.01) or top 1% (pr > 0.99) are flagged.
--
-- Nothing is deleted; flagging keeps the full distribution available
-- while letting analysis run on the clean core (is_outlier = 0).
--
-- Built as CREATE TABLE AS SELECT (one rebuild) rather than an UPDATE,
-- to avoid the undo-log / timeout cost of updating millions of rows.
-- This is the heaviest sort in the pipeline; raise the read timeout and
-- let it finish rather than re-running.
-- ---------------------------------------------------------------------
CREATE TABLE pp_flagged AS
SELECT
    tuid,
    price,
    transfer_date,
    sale_year,
    postcode,
    property_type,
    region_code,
    CASE
        WHEN pr < 0.01 OR pr > 0.99 THEN 1
        ELSE 0
    END AS is_outlier
FROM (
    SELECT
        tuid, price, transfer_date, sale_year,
        postcode, property_type, region_code,
        PERCENT_RANK() OVER (
            PARTITION BY region_code, sale_year
            ORDER BY price
        ) AS pr
    FROM pp_clean
) ranked;

-- Validation
SELECT is_outlier, COUNT(*) AS n                                 -- ~2% flagged as 1
FROM pp_flagged
GROUP BY is_outlier;

-- Price range of the KEPT sales per region (maxima should be expensive
-- but real, minima should be sensible rather than nominal transfers)
SELECT region_code, MIN(price) AS min_kept, MAX(price) AS max_kept
FROM pp_flagged
WHERE is_outlier = 0
GROUP BY region_code
ORDER BY region_code;

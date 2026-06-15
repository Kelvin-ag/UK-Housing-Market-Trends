-- =====================================================================
-- 04_build_clean.sql
-- Build the clean layer: attach region to each sale and apply scoping
-- filters so the data reflects standard residential market sales in
-- England only.
-- Input:  pp_raw, postcode_region
-- Output: pp_clean  (~8.9M rows)
-- =====================================================================

USE housing;

-- ---------------------------------------------------------------------
-- INNER JOIN drops any sale whose postcode does not match an English
-- region (Welsh and malformed postcodes fall out here), enforcing the
-- England-only scope. Filters:
--   property_type <> 'O'   homes only (excludes offices, land, car parks)
--   ppd_category  = 'A'    standard market sales (excludes repossessions
--                          and bulk / non-market transfers)
-- LIKE 'E12%' is belt-and-braces; postcode_region is already E12-only.
--
-- CREATE TABLE AS SELECT copies into a new physical table, roughly
-- doubling project disk use. pp_raw can be dropped and reloaded later
-- if space is ever tight. Heavy join over ~11M rows: raise the read
-- timeout and let it complete rather than re-running.
-- ---------------------------------------------------------------------
CREATE TABLE pp_clean AS
SELECT
    p.tuid,
    p.price,
    p.transfer_date,
    p.sale_year,
    p.postcode,
    p.property_type,
    r.region_code
FROM pp_raw p
INNER JOIN postcode_region r
    ON p.postcode = r.postcode
WHERE p.property_type <> 'O'
  AND p.ppd_category = 'A'
  AND r.region_code LIKE 'E12%';

-- Validation
SELECT COUNT(*) FROM pp_clean;                                   -- expect ~7-9M
SELECT region_code, COUNT(*) AS sales                            -- 9 E12 rows
FROM pp_clean
GROUP BY region_code
ORDER BY sales DESC;

-- How many rows the cleaning removed (provenance figure for the README)
SELECT
    (SELECT COUNT(*) FROM pp_raw)   AS raw_rows,
    (SELECT COUNT(*) FROM pp_clean) AS clean_rows,
    (SELECT COUNT(*) FROM pp_raw) - (SELECT COUNT(*) FROM pp_clean) AS dropped;

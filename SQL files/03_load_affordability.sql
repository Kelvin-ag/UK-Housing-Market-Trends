-- =====================================================================
-- 03_load_affordability.sql
-- Load the ONS affordability reference data: median price (1a),
-- median earnings (1b) and the published affordability ratio (1c),
-- assembled into one table at region-year grain.
-- Source: ONS "Ratio of house price to workplace-based earnings"
--         workbook, tables 1a/1b/1c, cleaned in Power Query to a tidy
--         CSV per table: Code, Name, Year, Value (E12 regions, 2015-2025).
-- Output: affordability_ref  (99 rows: 9 regions x 11 years).
-- =====================================================================

USE housing;

CREATE TABLE affordability_ref (
    region_code     CHAR(9),
    region_name     VARCHAR(50),
    sale_year       SMALLINT,
    median_price    INT,
    median_earnings INT,
    ratio           DECIMAL(5,2)
);

-- ---------------------------------------------------------------------
-- Step 1: load the ratio file (1c) as the base rows. This establishes
-- one row per region-year; price and earnings are filled in after.
-- Power Query CSVs have a header row, so IGNORE 1 LINES.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/Users/yourname/data/aff_ratio.csv'
INTO TABLE affordability_ref
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(region_code, region_name, sale_year, ratio);

-- ---------------------------------------------------------------------
-- Step 2: median price (1a). LOAD DATA can only insert, so load into a
-- temp table and UPDATE across on the region-year key. The join uses
-- key columns, so safe-update mode does not object.
-- ---------------------------------------------------------------------
CREATE TABLE price_tmp (
    region_code CHAR(9),
    region_name VARCHAR(50),
    sale_year   SMALLINT,
    median_price INT
);

LOAD DATA LOCAL INFILE '/Users/yourname/data/aff_price.csv'
INTO TABLE price_tmp
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(region_code, region_name, sale_year, median_price);

UPDATE affordability_ref a
JOIN price_tmp p
  ON a.region_code = p.region_code
 AND a.sale_year   = p.sale_year
SET a.median_price = p.median_price;

DROP TABLE price_tmp;

-- ---------------------------------------------------------------------
-- Step 3: median earnings (1b), same temp-table + UPDATE pattern.
-- ---------------------------------------------------------------------
CREATE TABLE earnings_tmp (
    region_code CHAR(9),
    region_name VARCHAR(50),
    sale_year   SMALLINT,
    median_earnings INT
);

LOAD DATA LOCAL INFILE '/Users/yourname/data/aff_earnings.csv'
INTO TABLE earnings_tmp
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(region_code, region_name, sale_year, median_earnings);

UPDATE affordability_ref a
JOIN earnings_tmp e
  ON a.region_code = e.region_code
 AND a.sale_year   = e.sale_year
SET a.median_earnings = e.median_earnings;

DROP TABLE earnings_tmp;

-- ---------------------------------------------------------------------
-- Step 4: drop Wales. The price-paid side is scoped to England only
-- (NSPL has no usable region for Welsh postcodes), so the Welsh row
-- here would never join. Remove it to keep both sides aligned.
-- ---------------------------------------------------------------------
DELETE FROM affordability_ref
WHERE region_code = 'W92000004';

-- Validation
SELECT COUNT(*) FROM affordability_ref;                          -- expect 99
SELECT region_code, sale_year, COUNT(*) AS n                     -- expect no rows
FROM affordability_ref
GROUP BY region_code, sale_year
HAVING n > 1;
SELECT * FROM affordability_ref
WHERE region_code = 'E12000007' AND sale_year = 2015;            -- London 2015 sanity

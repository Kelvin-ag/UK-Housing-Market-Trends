-- =====================================================================
-- 02_load_postcode_region.sql
-- Load the ONS National Statistics Postcode Lookup (NSPL), keeping only
-- the postcode and its region code, then restrict to the 9 English
-- regions (E12 codes).
-- Source: NSPL, CSVs split by postcode area.
-- Output: postcode_region  (postcode -> E12 region), indexed.
-- =====================================================================

USE housing;

CREATE TABLE postcode_region (
    postcode    VARCHAR(8),
    region_code CHAR(9)
);

-- ---------------------------------------------------------------------
-- Load. The NSPL has 35 columns; only two are wanted:
--   pcds     (col 3)  single-space postcode, matches Land Registry format
--   rgn25cd  (col 17) region code (E12... for England)
-- All other columns are read into throwaway @ variables.
-- Representative statement for one area file; all area CSVs were loaded
-- the same way via a shell loop. Header row present, so IGNORE 1 LINES.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/Users/yourname/nspl/area_file.csv'
INTO TABLE postcode_region
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@pcd7, @pcd8, postcode, @dointr, @doterm, @usrtypind, @east1m, @north1m,
 @gridind, @oa21cd, @cty25cd, @ced25cd, @lad25cd, @wd25cd, @nhser24cd,
 @ctry25cd, region_code, @pcon24cd, @ttwa15cd, @itl25cd, @npark16cd,
 @lsoa21cd, @msoa21cd, @wz11cd, @sicbl26cd, @bua24cd, @ruc21ind, @oac11ind,
 @lat, @long, @lep21cd1, @lep21cd2, @pfa23cd, @imd20ind, @icb26cd);

-- ---------------------------------------------------------------------
-- Scope to England. Scotland/Wales/NI come through as placeholder codes
-- (S99999999 / W99999999 / N99999999) and never match an English sale,
-- so they are removed to keep the lookup lean and the join key clean.
-- ---------------------------------------------------------------------
DELETE FROM postcode_region
WHERE region_code NOT LIKE 'E12%';

-- Index the join key (used against ~11.1M price-paid rows downstream).
CREATE INDEX idx_postcode ON postcode_region (postcode);

-- Validation
SELECT COUNT(*) FROM postcode_region;                            -- ~1.7-1.9M
SELECT region_code, COUNT(*) AS postcodes                        -- exactly 9 E12 rows
FROM postcode_region
GROUP BY region_code
ORDER BY postcodes DESC;
SELECT COUNT(*) FROM postcode_region WHERE postcode IS NULL OR postcode = '';  -- 0

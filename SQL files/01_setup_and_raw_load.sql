-- =====================================================================
-- 01_setup_and_raw_load.sql
-- Database setup and raw load of HM Land Registry Price Paid Data.
-- Source: HM Land Registry Price Paid, annual CSVs 2015-2025
--         (2015 ships in two parts; load both into the same table).
-- Output: pp_raw  (~11.1M rows), with derived sale_year and an index.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS housing;
USE housing;

-- Allow LOAD DATA LOCAL INFILE (server side).
-- Client side: add OPT_LOCAL_INFILE=1 to the Workbench connection's
-- Advanced options, then reconnect.
SET GLOBAL local_infile = 1;

-- ---------------------------------------------------------------------
-- Raw table: mirrors the 16 fixed columns of the Price Paid file.
-- The file has no header row, so the load uses no IGNORE clause.
-- ---------------------------------------------------------------------
CREATE TABLE pp_raw (
    tuid          VARCHAR(50),
    price         INT,
    transfer_date DATETIME,
    postcode      VARCHAR(10),
    property_type CHAR(1),
    old_new       CHAR(1),
    duration      CHAR(1),
    paon          VARCHAR(100),
    saon          VARCHAR(100),
    street        VARCHAR(100),
    locality      VARCHAR(100),
    town_city     VARCHAR(100),
    district      VARCHAR(100),
    county        VARCHAR(100),
    ppd_category  CHAR(1),
    record_status CHAR(1)
);

-- ---------------------------------------------------------------------
-- Load. Representative statement for one file; every annual CSV was
-- loaded the same way via a shell loop over the data folder. Each load
-- appends, so all years (and the two 2015 parts) accumulate in pp_raw.
-- Government CSVs are typically CRLF; switch to '\n' if rows misalign.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/Users/yourname/data/pp-2015-part1.csv'
INTO TABLE pp_raw
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
(tuid, price, transfer_date, postcode, property_type, old_new, duration,
 paon, saon, street, locality, town_city, district, county,
 ppd_category, record_status);

-- ---------------------------------------------------------------------
-- Derive sale_year as a STORED generated column rather than an UPDATE.
-- On a large table a single UPDATE builds a huge undo log and tends to
-- time out; a generated column is one efficient rebuild and back-fills
-- any rows loaded later automatically.
-- ---------------------------------------------------------------------
ALTER TABLE pp_raw
ADD COLUMN sale_year SMALLINT AS (YEAR(transfer_date)) STORED;

-- Build the index AFTER loading (faster than maintaining it per insert).
-- On older hardware this can run long and look hung but completes server
-- side; verify with SHOW INDEX FROM pp_raw before re-running.
CREATE INDEX idx_sale_year ON pp_raw (sale_year);

-- Validation
SELECT COUNT(*) AS total_rows FROM pp_raw;                       -- expect ~11.1M
SELECT sale_year, COUNT(*) AS sales
FROM pp_raw
GROUP BY sale_year
ORDER BY sale_year;                                              -- expect 2015-2025

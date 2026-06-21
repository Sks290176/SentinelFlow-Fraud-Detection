- =========================================================================
-- FORTIS COMPLIANCE ENTERPRISE PIPELINE (DAYS 1 - 9 RECONCILIATION)
-- Specialization: Financial Crime Detection & Behavioral Risk Scoring
-- =========================================================================

CREATE DATABASE IF NOT EXISTS fortis_compliance;
USE fortis_compliance;

-- -------------------------------------------------------------------------
-- DAYS 1-4: IMMUTABLE AUDIT STAGING SCHEMA
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS staging_transactions;
CREATE TABLE staging_transactions (
    `step` INT NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    `amount` DECIMAL(15, 2) NOT NULL,
    `nameOrig` VARCHAR(50) NOT NULL,
    `oldbalanceOrg` DECIMAL(15, 2) NOT NULL,
    `newbalanceOrig` DECIMAL(15, 2) NOT NULL,
    `nameDest` VARCHAR(50) NOT NULL,
    `oldbalanceDest` DECIMAL(15, 2) NOT NULL,
    `newbalanceDest` DECIMAL(15, 2) NOT NULL,
    `isFraud` TINYINT NOT NULL,
    `isFlaggedFraud` TINYINT NOT NULL
);

CREATE INDEX idx_nameOrig ON staging_transactions(nameOrig);
CREATE INDEX idx_nameDest ON staging_transactions(nameDest);

-- -------------------------------------------------------------------------
-- DAY 5: FAST SERVER-SIDE NATIVE INGESTION ENGINE
-- -------------------------------------------------------------------------
TRUNCATE TABLE staging_transactions;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PS_20174392719_1491204439457_log.csv'
INTO TABLE staging_transactions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- -------------------------------------------------------------------------
-- DAY 6: CROSS-BORDER CAPITAL EFFLUX PROFILING
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS high_risk_international;
CREATE TABLE high_risk_international AS
SELECT 
    nameOrig AS customer_id,
    SUM(amount) AS total_90_day_volume,
    MAX(amount) AS max_single_destination_outflow,
    (MAX(amount) / SUM(amount)) * 100 AS simulated_cross_border_ratio
FROM staging_transactions
GROUP BY nameOrig
HAVING simulated_cross_border_ratio > 70.0;

-- -------------------------------------------------------------------------
-- DAY 8: SYSTEM INTERACTION VELOCITY & REGIONAL RISK AGGREGATIONS
-- -------------------------------------------------------------------------
-- KPI 1: Average Dataset Transaction Velocity
SELECT COUNT(*) / COUNT(DISTINCT nameOrig) AS avg_transaction_velocity_per_user 
FROM staging_transactions;

-- KPI 2: High-Risk Source Distribution by Destination Region Profiles
SELECT 
    CASE 
        WHEN nameDest LIKE 'M%' THEN 'Merchant Ecosystem (Reg-A)'
        WHEN nameDest LIKE 'C%' THEN 'Customer Wallet Hub (Reg-B)'
        ELSE 'International Clearing'
    END AS simulated_region,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS high_risk_fraud_incidents,
    (SUM(isFraud) / COUNT(*)) * 100 AS high_risk_source_percentage
FROM staging_transactions
GROUP BY 1;

-- -------------------------------------------------------------------------
-- DAY 9: WEIGHTED CUSTOMER RISK SCORING LAYER & ANALYTICAL VIEW
-- -------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_customer_risk_scores AS
SELECT 
    t.nameOrig AS customer_id,
    COUNT(*) AS transaction_count,
    SUM(t.amount) AS total_volume,
    (SUM(t.isFraud) * 70.0) + (IFNULL(r.simulated_cross_border_ratio, 0) * 0.30) AS customer_risk_score
FROM staging_transactions t
LEFT JOIN high_risk_international r ON t.nameOrig = r.customer_id
GROUP BY t.nameOrig, r.simulated_cross_border_ratio;

-- Verification Final Sample Extractor
SELECT * FROM v_customer_risk_scores ORDER BY customer_risk_score DESC LIMIT 100;
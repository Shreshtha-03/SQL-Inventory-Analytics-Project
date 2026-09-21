--NORMALISATION OF DATASET

--creating schema to organise tables

CREATE SCHEMA IF NOT EXISTS inventory;
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'inventory';

--creating and populating dim_product table

CREATE TABLE inventory.dim_product (
    product_id VARCHAR(20) PRIMARY KEY,
    category VARCHAR(100) NOT NULL);
	
SELECT *
FROM inventory.dim_product;

INSERT INTO inventory.dim_product (
    product_id,
    category
)
SELECT DISTINCT
    product_id,
    category
FROM raw_inventory;

SELECT *
FROM inventory.dim_product
ORDER BY product_id;

--creating and populating dim_store table

CREATE TABLE inventory.dim_store (
    store_id VARCHAR(20) NOT NULL,
	region VARCHAR(20) NOT NULL,
	PRIMARY KEY(store_id, region)
);

INSERT INTO inventory.dim_store (
    store_id,
	region)
SELECT DISTINCT
    store_id, region
FROM raw_inventory;

SELECT *
FROM inventory.dim_store
ORDER BY store_id;

--creating and populating dim_date table

CREATE TABLE inventory.dim_date (
    date DATE PRIMARY KEY,
    year INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL,
    day INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    seasonality VARCHAR(50) NOT NULL
);

INSERT INTO inventory.dim_date (
    date,
    year,
    month,
    month_name,
    quarter,
    day,
    day_of_week,
    day_name,
    seasonality
)
SELECT DISTINCT
    date,
    EXTRACT(YEAR FROM date)::INT,
    EXTRACT(MONTH FROM date)::INT,
    TO_CHAR(date, 'Month'),
    EXTRACT(QUARTER FROM date)::INT,
    EXTRACT(DAY FROM date)::INT,
    EXTRACT(ISODOW FROM date)::INT,
    TO_CHAR(date, 'Day'),
    seasonality
FROM raw_inventory;

SELECT *
FROM inventory.dim_date
ORDER BY date
LIMIT 10;

--creating and populating fact_inventory table

CREATE TABLE inventory.fact_inventory (
    date DATE NOT NULL,
    store_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,

    region VARCHAR(50) NOT NULL,
    inventory_level INT NOT NULL,
    units_sold INT NOT NULL,
    units_ordered INT NOT NULL,
    demand_forecast NUMERIC(12,2) NOT NULL,
    price NUMERIC(12,2) NOT NULL,
    discount INT NOT NULL,
    weather_condition VARCHAR(50) NOT NULL,
    holiday_promotion INT NOT NULL,
    competitor_pricing NUMERIC(12,2) NOT NULL,

    PRIMARY KEY (date, store_id, product_id),

    FOREIGN KEY (date)
        REFERENCES inventory.dim_date(date),

    FOREIGN KEY (store_id,region)
        REFERENCES inventory.dim_store(store_id,region),

    FOREIGN KEY (product_id)
        REFERENCES inventory.dim_product(product_id)
);

INSERT INTO inventory.fact_inventory (
    date,
    store_id,
    product_id,
    region,
    inventory_level,
    units_sold,
    units_ordered,
    demand_forecast,
    price,
    discount,
    weather_condition,
    holiday_promotion,
    competitor_pricing
)
SELECT
    date,
    store_id,
    product_id,
    region,
    inventory_level,
    units_sold,
    units_ordered,
    demand_forecast,
    price,
    discount,
    weather_condition,
    holiday_promotion,
    competitor_pricing
FROM raw_inventory;

SELECT *
FROM inventory.fact_inventory;

--VALIDATION OF NORMALISED DATABASE:

--CHECK 1: validating tables

SELECT 'Products' AS table_name, COUNT(*) AS records
FROM inventory.dim_product

UNION ALL

SELECT 'Stores', COUNT(*)
FROM inventory.dim_store

UNION ALL

SELECT 'Dates', COUNT(*)
FROM inventory.dim_date

UNION ALL

SELECT 'Fact Inventory', COUNT(*)
FROM inventory.fact_inventory;

--CHECK 2: orphaned records:

SELECT COUNT(*) AS orphaned_records
FROM inventory.fact_inventory f
LEFT JOIN inventory.dim_product p
    ON f.product_id = p.product_id
LEFT JOIN inventory.dim_store s
    ON f.store_id = s.store_id
LEFT JOIN inventory.dim_date d
    ON f.date = d.date
WHERE p.product_id IS NULL
   OR s.store_id IS NULL
   OR d.date IS NULL;

--CHECK 3: Missing dates:

SELECT
    d.date
FROM inventory.dim_date d
LEFT JOIN inventory.fact_inventory f
    ON d.date = f.date
WHERE f.date IS NULL
ORDER BY d.date;

--CHECK 4: validating the composite key:

SELECT
    date,
    store_id,
    product_id,
    COUNT(*) AS duplicate_count
FROM inventory.fact_inventory
GROUP BY
    date,
    store_id,
    product_id
HAVING COUNT(*) > 1;

--CHECK 6: comparing the raw and normalised data

SELECT
    'Raw' AS source,
    COUNT(*) AS records,
    SUM(units_sold) AS total_units_sold,
    SUM(units_ordered) AS total_units_ordered,
    SUM(inventory_level) AS total_inventory
FROM raw_inventory

UNION ALL

SELECT
    'Normalized',
    COUNT(*),
    SUM(units_sold),
    SUM(units_ordered),
    SUM(inventory_level)
FROM inventory.fact_inventory;

--building sku classification
WITH sku_sales AS (
    SELECT
        f.product_id,
        p.category,
        SUM(f.units_sold) AS total_units_sold,
        AVG(f.inventory_level) AS avg_inventory,
        AVG(f.demand_forecast) AS avg_forecast
    FROM inventory.fact_inventory f
    JOIN inventory.dim_product p
        ON f.product_id = p.product_id
    GROUP BY
        f.product_id,
        p.category
),

ranked_skus AS (
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY total_units_sold DESC
        ) AS sales_quartile
    FROM sku_sales
)

SELECT
    product_id,
    category,
    total_units_sold,
    ROUND(avg_inventory, 2) AS avg_inventory,
    ROUND(avg_forecast, 2) AS avg_forecast,
    sales_quartile,
    CASE
        WHEN sales_quartile = 1 THEN 'Fast-moving'
        WHEN sales_quartile IN (2, 3) THEN 'Medium-moving'
        WHEN sales_quartile = 4 THEN 'Slow-moving'
    END AS movement_class
FROM ranked_skus
ORDER BY
    total_units_sold DESC;

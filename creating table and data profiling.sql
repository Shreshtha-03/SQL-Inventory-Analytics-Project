CREATE TABLE raw_inventory (
    date DATE,
    store_id VARCHAR(20),
    product_id VARCHAR(20),
    category VARCHAR(100),
    region VARCHAR(100),
    inventory_level INT,
    units_sold INT,
    units_ordered INT,
    demand_forecast NUMERIC(12,2),
    price NUMERIC(12,2),
    discount INT,
    weather_condition VARCHAR(50),
    holiday_promotion INT,
    competitor_pricing NUMERIC(12,2),
    seasonality VARCHAR(50)
);

SELECT * FROM raw_inventory;

SELECT COUNT(*)
FROM raw_inventory;

SELECT COUNT(DISTINCT store_id),
       COUNT(DISTINCT product_id)
FROM raw_inventory;

SELECT MIN(date),
       MAX(date)
FROM raw_inventory;

SELECT
    date,
    store_id,
    product_id,
    COUNT(*) AS record_count
FROM raw_inventory
GROUP BY date, store_id, product_id
HAVING COUNT(*) > 1;

SELECT 'date' AS column_name,
       COUNT(*) FILTER (WHERE date IS NULL) AS null_count
FROM raw_inventory

UNION ALL

SELECT 'store_id', 
       COUNT(*) FILTER (WHERE store_id IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'product_id',
       COUNT(*) FILTER (WHERE product_id IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'category',
       COUNT(*) FILTER (WHERE category IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'region',
       COUNT(*) FILTER (WHERE region IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'inventory_level',
       COUNT(*) FILTER (WHERE inventory_level IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'units_sold',
       COUNT(*) FILTER (WHERE units_sold IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'units_ordered',
       COUNT(*) FILTER (WHERE units_ordered IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'demand_forecast',
       COUNT(*) FILTER (WHERE demand_forecast IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'price',
       COUNT(*) FILTER (WHERE price IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'discount',
       COUNT(*) FILTER (WHERE discount IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'weather_condition',
       COUNT(*) FILTER (WHERE weather_condition IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'holiday_promotion',
       COUNT(*) FILTER (WHERE holiday_promotion IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'competitor_pricing',
       COUNT(*) FILTER (WHERE competitor_pricing IS NULL)
FROM raw_inventory

UNION ALL

SELECT 'seasonality',
       COUNT(*) FILTER (WHERE seasonality IS NULL)
FROM raw_inventory;


SELECT
    product_id,
    COUNT(DISTINCT category) AS category_count
FROM raw_inventory
GROUP BY product_id
HAVING COUNT(DISTINCT category) > 1;

SELECT store_id,
COUNT(DISTINCT region) as region_count
FROM raw_inventory
GROUP BY store_id
HAVING COUNT(DISTINCT region)>1;

SELECT
    store_id,
    region,
    COUNT(*) AS record_count
FROM raw_inventory
GROUP BY store_id, region
ORDER BY store_id, region;

SELECT
    store_id,
    COUNT(DISTINCT region) AS region_count,
    STRING_AGG(DISTINCT region, ', ' ORDER BY region) AS regions
FROM raw_inventory
GROUP BY store_id
ORDER BY store_id;

SELECT
    store_id,
    date,
    COUNT(DISTINCT region) AS region_count
FROM raw_inventory
GROUP BY store_id, date
HAVING COUNT(DISTINCT region) > 1;

SELECT
    store_id,
    product_id,
    COUNT(DISTINCT region) AS region_count
FROM raw_inventory
GROUP BY store_id, product_id
HAVING COUNT(DISTINCT region) > 1;

SELECT
    date,
    product_id,
    COUNT(DISTINCT region) AS region_count
FROM raw_inventory
GROUP BY date, product_id
HAVING COUNT(DISTINCT region) > 1;

SELECT
    date,
    category,
    COUNT(DISTINCT region) AS region_count
FROM raw_inventory
GROUP BY date, category
HAVING COUNT(DISTINCT region) > 1;

SELECT
    product_id,
    category,
    COUNT(DISTINCT region) AS region_count
FROM raw_inventory
GROUP BY product_id, category
HAVING COUNT(DISTINCT region) > 1;


SELECT
    store_id,
    product_id,
    date,
    COUNT(DISTINCT region) AS region_count
FROM raw_inventory
GROUP BY
    store_id,
    product_id,
    date
HAVING COUNT(DISTINCT region) > 1;

SELECT
    date,
    COUNT(DISTINCT seasonality) AS seasonality_count
FROM raw_inventory
GROUP BY date
HAVING COUNT(DISTINCT seasonality) > 1;

SELECT
    date,
    COUNT(DISTINCT weather_condition) AS weather_count
FROM raw_inventory
GROUP BY date
HAVING COUNT(DISTINCT weather_condition) > 1;

SELECT
    date,
    COUNT(DISTINCT holiday_promotion) AS promotion_count
FROM raw_inventory
GROUP BY date
HAVING COUNT(DISTINCT holiday_promotion) > 1;

SELECT
    date,
    COUNT(DISTINCT competitor_pricing) AS competitor_price_count
FROM raw_inventory
GROUP BY date
HAVING COUNT(DISTINCT competitor_pricing) > 1;

SELECT
    store_id,
    region,
    COUNT(*) AS records
FROM raw_inventory
GROUP BY store_id, region
ORDER BY store_id, region;

SELECT
    product_id,
    COUNT(DISTINCT category) AS category_count
FROM raw_inventory
GROUP BY product_id
ORDER BY product_id;

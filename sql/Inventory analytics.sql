-- INVENTORY ANALYTICS

--Section 1: PORTFOLIO EXPLORATION & EXPLORATORY DATA ANALYSIS (EDA).

-- 1.1 Global Inventory & Sales Baseline Audit
SELECT
    COUNT(*) AS total_records,
    SUM(units_sold) AS total_units_sold,
    SUM(units_ordered) AS total_units_ordered,
    AVG(inventory_level) AS avg_inventory_level,
    MIN(inventory_level) AS min_inventory_level,
    MAX(inventory_level) AS max_inventory_level,
    AVG(units_sold) AS avg_daily_units_sold,
    AVG(demand_forecast) AS avg_demand_forecast
FROM inventory.fact_inventory;

-- 1.2 Temporal Seasonality & Monthly Demand Trends
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.units_sold) AS total_units_sold,
    SUM(f.units_ordered) AS total_units_ordered,
    AVG(f.inventory_level) AS avg_inventory_level,
    AVG(f.demand_forecast) AS avg_demand_forecast
FROM inventory.fact_inventory f
JOIN inventory.dim_date d
    ON f.date = d.date
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;
	
-- 1.3 Category-Level Performance & Revenue Concentration
SELECT
    p.category,
    COUNT(DISTINCT f.product_id) AS products,
    SUM(f.units_sold) AS total_units_sold,
	ROUND(
        100.0 * SUM(f.units_sold * f.price) / SUM(SUM(f.units_sold * f.price)) OVER (),
        2
    ) AS pct_of_total_revenue,
    SUM(f.units_ordered) AS total_units_ordered,
    AVG(f.inventory_level) AS avg_inventory_level,
    AVG(f.demand_forecast) AS avg_demand_forecast
FROM inventory.fact_inventory f
JOIN inventory.dim_product p
    ON f.product_id = p.product_id
GROUP BY p.category
ORDER BY total_units_sold DESC;

-- 1.4 Store-Level Throughput & Revenue Share
SELECT
    store_id,
    COUNT(DISTINCT product_id) AS products,
    SUM(units_sold) AS total_units_sold,
	ROUND(
        100.0 * SUM(units_sold * price) / SUM(SUM(units_sold * price)) OVER (),
        2
    ) AS pct_of_total_revenue,
    SUM(units_ordered) AS total_units_ordered,
    AVG(inventory_level) AS avg_inventory_level,
    AVG(demand_forecast) AS avg_demand_forecast
FROM inventory.fact_inventory
GROUP BY store_id
ORDER BY total_units_sold DESC;

-- 1.5 Regional Macro Performance Breakdown
SELECT
    region,
    COUNT(*) AS records,
    SUM(units_sold) AS total_units_sold,
	ROUND(
        100.0 * SUM(units_sold * price) / SUM(SUM(units_sold * price)) OVER (),
        2
    ) AS pct_of_total_revenue,
    SUM(units_ordered) AS total_units_ordered,
    AVG(inventory_level) AS avg_inventory_level,
    AVG(demand_forecast) AS avg_demand_forecast
FROM inventory.fact_inventory
GROUP BY region
ORDER BY total_units_sold DESC;

--Section 2: STOCKOUT AUDIT & INVENTORY HEALTH DIAGNOSTICS

-- 2.1 Overall Portfolio Stockout Rate Baseline
SELECT
    COUNT(*) AS stockout_records,
    COUNT(*) * 100.0 /(SELECT COUNT(*) FROM inventory.fact_inventory) AS stockout_rate_pct
FROM inventory.fact_inventory
WHERE inventory_level = 0;

-- 2.2 Stockout Frequency by Product & Category
SELECT
    f.product_id,
    p.category,
    COUNT(*) AS total_days,
    SUM(
        CASE
            WHEN f.inventory_level = 0 THEN 1
            ELSE 0
        END
    ) AS stockout_days,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN f.inventory_level = 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS stockout_rate_pct
FROM inventory.fact_inventory f
JOIN inventory.dim_product p
    ON f.product_id = p.product_id
GROUP BY
    f.product_id,
    p.category
ORDER BY stockout_rate_pct DESC;

-- 2.3 Inventory Coverage Analysis (Inventory vs. Forecast Demand)
SELECT
    f.product_id,
    p.category,
    ROUND(AVG(f.inventory_level), 2) AS avg_inventory,
    ROUND(AVG(f.demand_forecast), 2) AS avg_forecast,
    ROUND(
        AVG(f.inventory_level) /
        NULLIF(AVG(f.demand_forecast), 0),
        2
    ) AS avg_inventory_coverage
FROM inventory.fact_inventory f
JOIN inventory.dim_product p
    ON f.product_id = p.product_id
GROUP BY
    f.product_id,
    p.category
ORDER BY
    avg_inventory_coverage DESC;

-- Section 3: EXTERNAL & ENVIRONMENTAL DEMAND DRIVERS (Seasonality, Weather, Pricing)

-- 3.1 Category-Level Seasonality & Weather Sensitivity (Filtered for Store S001 / East Region)
SELECT 
    p.category,
    
    -- Seasonality Impact
    ROUND(AVG(CASE WHEN d.seasonality = 'Winter' THEN f.units_sold END), 2) AS winter_avg_sales,
    ROUND(AVG(CASE WHEN d.seasonality = 'Summer' THEN f.units_sold END), 2) AS summer_avg_sales,
    ROUND(AVG(CASE WHEN d.seasonality = 'Spring' THEN f.units_sold END), 2) AS spring_avg_sales,
    ROUND(AVG(CASE WHEN d.seasonality = 'Autumn' THEN f.units_sold END), 2) AS autumn_avg_sales,
    
    -- Weather Impact
    ROUND(AVG(CASE WHEN f.weather_condition = 'Rainy' THEN f.units_sold END), 2) AS rainy_avg_sales,
    ROUND(AVG(CASE WHEN f.weather_condition = 'Sunny' THEN f.units_sold END), 2) AS sunny_avg_sales,
    ROUND(AVG(CASE WHEN f.weather_condition = 'Snowy' THEN f.units_sold END), 2) AS snowy_avg_sales,
    ROUND(AVG(CASE WHEN f.weather_condition = 'Cloudy' THEN f.units_sold END), 2) AS cloudy_avg_sales,
    
    -- Competitor Price Difference (Positive = Store is more expensive)
    ROUND(AVG(f.price - f.competitor_pricing), 2) AS avg_price_diff,
    ROUND(AVG(f.units_sold), 2) AS overall_avg_sales

FROM inventory.fact_inventory f
JOIN inventory.dim_product p 
    ON f.product_id = p.product_id
JOIN inventory.dim_date d 
    ON f.date = d.date
WHERE 
    f.store_id = 'S001' 
    AND f.region = 'East'
GROUP BY 
    p.category
ORDER BY 
    overall_avg_sales DESC;

-- 3.2 Granular SKU-Level Environmental & Pricing Drivers
SELECT 
    f.product_id,
    p.category,
    
    -- Overall Product Performance
    ROUND(AVG(f.units_sold), 2) AS overall_avg_sales,
    
    -- Seasonal Demand
    ROUND(AVG(CASE WHEN d.seasonality = 'Winter' THEN f.units_sold END), 2) AS winter_sales,
    ROUND(AVG(CASE WHEN d.seasonality = 'Summer' THEN f.units_sold END), 2) AS summer_sales,
    
    -- Weather Sensitivity
    ROUND(AVG(CASE WHEN f.weather_condition = 'Rainy' THEN f.units_sold END), 2) AS rainy_sales,
    ROUND(AVG(CASE WHEN f.weather_condition = 'Sunny' THEN f.units_sold END), 2) AS sunny_sales,
    
    -- Pricing Dynamics
    ROUND(AVG(f.price), 2) AS avg_store_price,
    ROUND(AVG(f.competitor_pricing), 2) AS avg_comp_price,
    ROUND(AVG(f.price - f.competitor_pricing), 2) AS avg_price_gap

FROM inventory.fact_inventory f
JOIN inventory.dim_product p 
    ON f.product_id = p.product_id
JOIN inventory.dim_date d 
    ON f.date = d.date
WHERE 
    f.store_id = 'S001' 
    AND f.region = 'East'
GROUP BY 
    f.product_id, 
    p.category
ORDER BY 
    p.category, 
    overall_avg_sales DESC;

-- 3.3 Competitive Price Positioning & Revenue Impact (Market Elasticity Insight)
SELECT 
    p.category,
    CASE 
        WHEN f.price < f.competitor_pricing THEN '1. Cheaper than Competitor'
        WHEN f.price = f.competitor_pricing THEN '2. Same Price'
        ELSE '3. More Expensive than Competitor'
    END AS price_positioning,
    COUNT(*) AS record_count,
    ROUND(AVG(f.price), 2) AS avg_store_price,
    ROUND(AVG(f.competitor_pricing), 2) AS avg_comp_price,
    ROUND(AVG(f.units_sold), 2) AS avg_units_sold,
    ROUND(SUM(f.units_sold * f.price), 2) AS total_revenue
FROM inventory.fact_inventory f
JOIN inventory.dim_product p 
    ON f.product_id = p.product_id
GROUP BY 
    p.category, 
    price_positioning
ORDER BY 
    p.category, 
    price_positioning;

-- Section 4: PROMOTIONAL & HOLIDAY LIFT ANALYSIS

-- 4.1 Category-Level Promotional Lift Performance(filtered for S001 and east region)
SELECT 
    p.category,
    ROUND(AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END), 2) AS regular_day_avg_sales,
    ROUND(AVG(CASE WHEN f.holiday_promotion = 1 THEN f.units_sold END), 2) AS promo_day_avg_sales,
    
    -- Absolute Lift (Units)
    ROUND(
        AVG(CASE WHEN f.holiday_promotion = 1 THEN f.units_sold END) - 
        AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END), 
        2
    ) AS sales_lift_units,
    
    -- Percentage Lift (%)
    ROUND(
        ((AVG(CASE WHEN f.holiday_promotion = 1 THEN f.units_sold END) - 
          AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END)) / 
          NULLIF(AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END), 0)) * 100, 
        2
    ) AS sales_lift_pct

FROM inventory.fact_inventory f
JOIN inventory.dim_product p 
    ON f.product_id = p.product_id
WHERE 
    f.store_id = 'S001' 
    AND f.region = 'East'
GROUP BY 
    p.category
ORDER BY 
    sales_lift_pct DESC;

-- 4.2 Granular SKU-Level Promotional Lift Performance
SELECT 
    f.product_id,
    p.category,
    ROUND(AVG(f.units_sold), 2) AS overall_avg_sales,
    ROUND(AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END), 2) AS regular_day_avg_sales,
    ROUND(AVG(CASE WHEN f.holiday_promotion = 1 THEN f.units_sold END), 2) AS promo_day_avg_sales,
    
    -- Absolute Lift (Units)
    ROUND(
        AVG(CASE WHEN f.holiday_promotion = 1 THEN f.units_sold END) - 
        AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END), 
        2
    ) AS sales_lift_units,
    
    -- Percentage Lift (%)
    ROUND(
        ((AVG(CASE WHEN f.holiday_promotion = 1 THEN f.units_sold END) - 
          AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END)) / 
          NULLIF(AVG(CASE WHEN f.holiday_promotion = 0 THEN f.units_sold END), 0)) * 100, 
        2
    ) AS sales_lift_pct

FROM inventory.fact_inventory f
JOIN inventory.dim_product p 
    ON f.product_id = p.product_id
WHERE 
    f.store_id = 'S001' 
    AND f.region = 'East'
GROUP BY 
    f.product_id, 
    p.category
ORDER BY 
    p.category, 
    sales_lift_pct DESC;

--Section 5: DEMAND FORECAST EVALUATION & ACCURACY AUDIT (WAPE, BIAS, AND SKU FORECAST DRIFT ERROR)

-- 5.1 Proof: Identifying zero-demand days that disqualify MAPE (division by zero risk)
SELECT
    COUNT(*) AS zero_sales_records
FROM inventory.fact_inventory
WHERE units_sold = 0;

-- 5.2 Macro Forecast Quality: Overall WAPE and systematic bias
SELECT
    ROUND(
        100.0 * SUM(ABS(units_sold - demand_forecast)) / NULLIF(SUM(units_sold), 0),
        2
    ) AS wape_pct,
    ROUND(
        100.0 * AVG(demand_forecast - units_sold) / NULLIF(AVG(units_sold), 0),
        2
    ) AS forecast_bias_pct
FROM inventory.fact_inventory;

-- 5.3 Micro Forecast Drift: Product-level forecast error ranking
SELECT
    f.product_id,
    p.category,
    ROUND(AVG(f.units_sold), 2) AS avg_units_sold,
    ROUND(AVG(f.demand_forecast), 2) AS avg_forecast,
    ROUND(AVG(f.demand_forecast - f.units_sold), 2) AS avg_forecast_error
FROM inventory.fact_inventory f
JOIN inventory.dim_product p
    ON f.product_id = p.product_id
GROUP BY f.product_id, p.category
ORDER BY avg_forecast_error DESC;

--Section 6: INVENTORY VELOCITY & SKU CLASSIFICATION (FAST/MEDIUM/SLOW SEGMENTATION USING WINDOW FUNCTIONS)

-- 6.1 Advanced Inventory Health: Days of Supply, Turnover, and FSN Classification
WITH store_region_product_aggregates AS (
    SELECT 
        f.store_id,
        f.region,
        f.product_id,
        p.category,
        
        -- 1. Averages
        ROUND(AVG(f.inventory_level), 2) AS avg_inventory,
        ROUND(AVG(f.units_sold), 2) AS avg_daily_sold,
        SUM(f.units_sold) AS total_units_sold,
        
        -- 2. Days of Supply = AVG(Inventory) / AVG(Units Sold)
        ROUND(
            AVG(f.inventory_level)::NUMERIC / NULLIF(AVG(f.units_sold), 0), 
            4
        ) AS days_of_supply,
        
        -- 3. Daily Turnover Ratio = AVG(Units Sold) / AVG(Inventory)
        ROUND(
            AVG(f.units_sold)::NUMERIC / NULLIF(AVG(f.inventory_level), 0), 
            4
        ) AS daily_turnover_ratio,

        -- 4. Percent Rank within Store + Region
        PERCENT_RANK() OVER (
            PARTITION BY f.store_id, f.region 
            ORDER BY (AVG(f.inventory_level)::NUMERIC / NULLIF(AVG(f.units_sold), 0)) ASC
        ) AS supply_pct_rank

    FROM inventory.fact_inventory f
    JOIN inventory.dim_product p 
        ON f.product_id = p.product_id
    GROUP BY 
        f.store_id, 
        f.region, 
        f.product_id, 
        p.category
)
SELECT 
    store_id,
    region,
    product_id,
    category,
    avg_inventory,
    avg_daily_sold,
    days_of_supply,
    daily_turnover_ratio,
    ROUND(daily_turnover_ratio * 365, 2) AS annualized_turns,
    
    -- Movement Classification
    CASE 
        WHEN total_units_sold = 0 THEN 'Non-Moving'
        WHEN supply_pct_rank <= 0.30 THEN 'Fast-Moving'
        WHEN supply_pct_rank <= 0.75 THEN 'Medium-Moving'
        ELSE 'Slow-Moving'
    END AS movement_status

FROM store_region_product_aggregates
ORDER BY 
    store_id, 
    region, 
    days_of_supply ASC;

--Section 7: PRESCRIPTIVE POLICY ENGINE (SAFETY STOCK, $Z$-SCORES, AND REORDER POINTS)

WITH daily_stats AS (
    SELECT 
        f.store_id,
        f.region,
        f.product_id,
        p.category,
        
        -- Sales & Inventory Averages
        AVG(f.units_sold)::NUMERIC AS avg_daily_sales,
        STDDEV_POP(f.units_sold)::NUMERIC AS std_daily_sales,
        AVG(f.inventory_level)::NUMERIC AS avg_inventory_level,
        COUNT(*) AS total_recorded_days,
        
        -- Stockout Condition Counts
        COUNT(CASE WHEN f.units_sold >= f.inventory_level OR f.inventory_level = 0 THEN 1 END) AS stockout_days,
        COUNT(CASE WHEN f.demand_forecast > f.inventory_level THEN 1 END) AS unmet_demand_days

    FROM inventory.fact_inventory f
    JOIN inventory.dim_product p 
        ON f.product_id = p.product_id
    GROUP BY 
        f.store_id, 
        f.region, 
        f.product_id, 
        p.category
),
rop_calculations AS (
    SELECT 
        store_id,
        region,
        product_id,
        category,
        ROUND(avg_inventory_level, 2) AS avg_inventory_level,
        ROUND(avg_daily_sales, 2) AS avg_daily_sales,
        
        -- 1. Stockout Rates (%)
        ROUND((stockout_days::NUMERIC / total_recorded_days) * 100, 2) AS stockout_rate_pct,
        ROUND((unmet_demand_days::NUMERIC / total_recorded_days) * 100, 2) AS unmet_forecast_risk_pct,
        
        -- 2. Safety Stock (Explicit ::NUMERIC cast)
        ROUND((1.645 * std_daily_sales * SQRT(1))::NUMERIC, 2) AS safety_stock,
        
        -- 3. Reorder Point = (Avg Sales * 1 day) + Safety Stock
        ROUND((avg_daily_sales + (1.645 * std_daily_sales * SQRT(1)))::NUMERIC, 2) AS reorder_point

    FROM daily_stats
)
SELECT 
    store_id,
    region,
    product_id,
    category,
    avg_inventory_level,
    reorder_point,
    safety_stock,
    stockout_rate_pct,
    unmet_forecast_risk_pct,
    
    -- 4. Excess Inventory Calculation
    GREATEST(0, ROUND((avg_inventory_level - reorder_point)::NUMERIC, 2)) AS excess_inventory_units,
    
    -- Stock Health Flag
    CASE 
        WHEN avg_inventory_level < reorder_point THEN 'Understocked / High Stockout Risk'
        WHEN avg_inventory_level > (reorder_point * 1.25) THEN 'Excess Stock'
        ELSE 'Optimally Stocked'
    END AS stock_health_status

FROM rop_calculations
ORDER BY 
    stockout_rate_pct DESC, 
    excess_inventory_units DESC;

















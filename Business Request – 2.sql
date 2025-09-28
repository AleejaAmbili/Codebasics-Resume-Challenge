WITH YearlyCategoryRevenue AS (
    SELECT
        CAST(RIGHT(far.`quarter-year`, 4) AS SIGNED) AS `year`,
        far.ad_category,
        CAST(REPLACE(REPLACE(far.Revenue_INR, ',', ''), '₹', '') AS DECIMAL(15,2)) AS clean_revenue
    FROM fact_ad_revenue far
    WHERE far.`quarter-year` REGEXP '[0-9]{4}$'
      AND far.Revenue_INR IS NOT NULL
),
CategoryAndTotalRevenue AS (
    SELECT
        ycr.`year`,
        dac.standard_ad_category AS category_name,
        SUM(ycr.clean_revenue) AS category_revenue,
        SUM(SUM(ycr.clean_revenue)) OVER (PARTITION BY ycr.`year`) AS total_revenue_year
    FROM YearlyCategoryRevenue ycr
    JOIN dim_ad_category dac ON ycr.ad_category = dac.ad_category_id
    GROUP BY ycr.`year`, dac.standard_ad_category
)
SELECT
    `year`,
    category_name,
    category_revenue,
    total_revenue_year,
    ROUND((category_revenue / total_revenue_year) * 100, 2) AS pct_of_year_total
FROM CategoryAndTotalRevenue
ORDER BY `year`, pct_of_year_total DESC
LIMIT 0, 1000;




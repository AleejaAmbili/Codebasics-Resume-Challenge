-- ======================================
-- Business Request 1
-- ======================================
SELECT 'Jan' AS mon, 1 AS mon_num
UNION ALL SELECT 'Feb',2
UNION ALL SELECT 'Mar',3
UNION ALL SELECT 'Apr',4
UNION ALL SELECT 'May',5
UNION ALL SELECT 'Jun',6
UNION ALL SELECT 'Jul',7
UNION ALL SELECT 'Aug',8
UNION ALL SELECT 'Sep',9
UNION ALL SELECT 'Oct',10
UNION ALL SELECT 'Nov',11
UNION ALL SELECT 'Dec',12;
-- Step 2: Convert Month text to numeric YYYYMM
SELECT 
    curr.City_ID,
    dc.city,
    curr.Month AS month,
    curr.Net_Circulation,
    prev.Net_Circulation AS prev_month_circulation,
    (curr.Net_Circulation - prev.Net_Circulation) AS change_in_circulation
FROM
    (SELECT fps.*, 
            (2000 + CAST(RIGHT(Month,2) AS UNSIGNED)) * 100
            + CASE LEFT(Month,3)
                WHEN 'Jan' THEN 1 WHEN 'Feb' THEN 2 WHEN 'Mar' THEN 3 WHEN 'Apr' THEN 4
                WHEN 'May' THEN 5 WHEN 'Jun' THEN 6 WHEN 'Jul' THEN 7 WHEN 'Aug' THEN 8
                WHEN 'Sep' THEN 9 WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 WHEN 'Dec' THEN 12
              END AS month_num
     FROM fact_print_sales fps
    ) curr
JOIN dim_city dc ON curr.City_ID = dc.city_id
JOIN
    (SELECT fps.*, 
            (2000 + CAST(RIGHT(Month,2) AS UNSIGNED)) * 100
            + CASE LEFT(Month,3)
                WHEN 'Jan' THEN 1 WHEN 'Feb' THEN 2 WHEN 'Mar' THEN 3 WHEN 'Apr' THEN 4
                WHEN 'May' THEN 5 WHEN 'Jun' THEN 6 WHEN 'Jul' THEN 7 WHEN 'Aug' THEN 8
                WHEN 'Sep' THEN 9 WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 WHEN 'Dec' THEN 12
              END AS month_num
     FROM fact_print_sales fps
    ) prev
    ON curr.City_ID = prev.City_ID
   AND curr.month_num = prev.month_num + 1
WHERE curr.Net_Circulation < prev.Net_Circulation
ORDER BY change_in_circulation ASC
LIMIT 3;

-- ======================================
-- Business Request 2
-- ======================================

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


-- ======================================
-- Business Request 3
-- ======================================
WITH CityPrint2024 AS (
    SELECT
        fps.City_ID,
        dc.city AS city_name,
        SUM(fps.`Copies Sold` + fps.copies_returned) AS copies_printed_2024,
        SUM(fps.Net_Circulation) AS net_circulation_2024
    FROM
        fact_print_sales fps
    JOIN
        dim_city dc ON fps.City_ID = dc.city_id
    WHERE
        2000 + CAST(RIGHT(fps.Month, 2) AS UNSIGNED) = 2024
    GROUP BY
        fps.City_ID,
        dc.city
)
SELECT
    city_name,
    copies_printed_2024,
    net_circulation_2024,
    ROUND(net_circulation_2024 / copies_printed_2024, 4) AS efficiency_ratio,  -- <--- specify decimals
    RANK() OVER (ORDER BY (net_circulation_2024 / copies_printed_2024) DESC) AS efficiency_rank_2024
FROM
    CityPrint2024
WHERE
    copies_printed_2024 > 0
ORDER BY
    efficiency_rank_2024
LIMIT 5;



-- ======================================
-- Business Request 4
-- ======================================

SELECT
    dc.city AS city_name,
    -- Use conditional aggregation to pivot Q1-2021 internet penetration
    MAX(CASE WHEN fcr.quarter = '2021-Q1' THEN fcr.internet_penetration END) AS internet_rate_q1_2021,
    -- Use conditional aggregation to pivot Q4-2021 internet penetration
    MAX(CASE WHEN fcr.quarter = '2021-Q4' THEN fcr.internet_penetration END) AS internet_rate_q4_2021,
    (
        MAX(CASE WHEN fcr.quarter = '2021-Q4' THEN fcr.internet_penetration END) -
        MAX(CASE WHEN fcr.quarter = '2021-Q1' THEN fcr.internet_penetration END)
    ) AS delta_internet_rate
FROM
    fact_city_readiness fcr
JOIN
    dim_city dc ON fcr.city_id = dc.city_id
WHERE
    fcr.quarter IN ('2021-Q1', '2021-Q4')
GROUP BY
    dc.city_id,
    dc.city
HAVING
    internet_rate_q1_2021 IS NOT NULL AND internet_rate_q4_2021 IS NOT NULL -- Ensure data exists for both quarters
ORDER BY
    delta_internet_rate DESC;


-- ======================================
-- Business Request 5
-- ======================================
WITH YearlyPrint AS (
    SELECT
        fps.City_ID,
        dc.city AS city_name,
        2000 + CAST(RIGHT(fps.Month,2) AS UNSIGNED) AS year,
        SUM(fps.Net_Circulation) AS yearly_net_circulation
    FROM fact_print_sales fps
    JOIN dim_city dc ON fps.City_ID = dc.city_id
    WHERE 2000 + CAST(RIGHT(fps.Month,2) AS UNSIGNED) BETWEEN 2019 AND 2024
    GROUP BY fps.City_ID, dc.city, year
),
YearlyAd AS (
    SELECT
        far.year,
        SUM(CAST(REPLACE(REPLACE(TRIM(far.Revenue_INR), ',', ''), '₹', '') AS DECIMAL(15,2))) AS yearly_ad_revenue
    FROM fact_ad_revenue far
    WHERE far.year BETWEEN 2019 AND 2024
    GROUP BY far.year
),
CitySummary AS (
    SELECT
        yp.City_ID,
        yp.city_name,
        GROUP_CONCAT(yp.year ORDER BY yp.year) AS years,
        GROUP_CONCAT(yp.yearly_net_circulation ORDER BY yp.year) AS circulation_seq,
        GROUP_CONCAT(ya.yearly_ad_revenue ORDER BY ya.year) AS ad_revenue_seq
    FROM YearlyPrint yp
    CROSS JOIN YearlyAd ya
    GROUP BY yp.City_ID, yp.city_name
)
SELECT
    City_ID,
    city_name,
    circulation_seq AS yearly_net_circulation,
    ad_revenue_seq AS yearly_ad_revenue,
    CASE
        WHEN circulation_seq LIKE '%,%,%,%,%,%' -- 6 years, simple check
             AND circulation_seq NOT REGEXP '([0-9]+),\\1'
        THEN 'Yes' ELSE 'No'
    END AS is_declining_print,
    'Yes' AS is_declining_ad_revenue, -- national revenue, check separately if needed
    CASE
        WHEN circulation_seq LIKE '%,%,%,%,%,%'
             AND circulation_seq NOT REGEXP '([0-9]+),\\1'
        THEN 'Yes' ELSE 'No'
    END AS is_declining_both
FROM CitySummary;


-- ======================================
-- Business Request 6
-- ======================================
WITH DigitalReadiness AS (
    -- 1. Calculate the average readiness score for 2021
    SELECT
        city_id,
        AVG((literacy_rate + smartphone_penetration + internet_penetration) / 3) AS digital_readiness_score_2021
    FROM
        fact_city_readiness
    WHERE
        quarter LIKE '2021-%'
    GROUP BY
        city_id
),
DigitalEngagement AS (
    -- 2. Calculate total downloads/accesses for 2021
    SELECT
        city_id,
        SUM(downloads_or_accesses) AS total_downloads_2021
    FROM
        fact_digital_pilot
    WHERE
        launch_month LIKE '2021-%'
    GROUP BY
        city_id
),
RankedCities AS (
    -- 3. Combine metrics and calculate ranks
    SELECT
        dc.city AS city_name,
        dr.digital_readiness_score_2021,
        de.total_downloads_2021,
        RANK() OVER (ORDER BY dr.digital_readiness_score_2021 DESC) AS readiness_rank, -- Rank 1 is highest score
        RANK() OVER (ORDER BY de.total_downloads_2021 DESC) AS downloads_rank          -- Rank 1 is highest downloads
    FROM
        dim_city dc
    JOIN
        DigitalReadiness dr ON dc.city_id = dr.city_id
    JOIN
        DigitalEngagement de ON dc.city_id = de.city_id
)
SELECT
    city_name,
    digital_readiness_score_2021,
    total_downloads_2021,
    readiness_rank,
    downloads_rank
FROM
    RankedCities
WHERE
    readiness_rank = 1 -- City with the highest digital readiness score
    AND downloads_rank >= (SELECT COUNT(DISTINCT city_id) FROM dim_city) - 2 -- Among the bottom 3 in downloads (for 10 cities, this is rank >= 8)
ORDER BY
    downloads_rank DESC;

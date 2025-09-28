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

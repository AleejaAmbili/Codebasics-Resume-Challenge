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
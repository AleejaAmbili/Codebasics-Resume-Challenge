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

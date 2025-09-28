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
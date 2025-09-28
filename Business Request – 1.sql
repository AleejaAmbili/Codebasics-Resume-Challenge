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


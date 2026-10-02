WITH nearest AS (
    SELECT
        s.station_id,
        s.station_code,
        s.station_name,
        d.district_id AS nearest_district_id,
        d.district_name AS nearest_district_name,
        ST_Distance(s.geom, d.geom) AS distance_m
    FROM bj_life.transit_station s
    CROSS JOIN LATERAL (
        SELECT
            d.district_id,
            d.district_name,
            d.geom
        FROM bj_life.district d
        ORDER BY d.geom <-> s.geom
        LIMIT 1
    ) d
    WHERE s.district_id IS NULL
)
SELECT
    CASE
        WHEN distance_m = 0 THEN '行政区边界点'
        WHEN distance_m <= 100 THEN '距离边界100米以内'
        WHEN distance_m <= 500 THEN '距离边界100至500米'
        WHEN distance_m <= 2000 THEN '距离边界500至2000米'
        ELSE '距离北京超过2000米'
    END AS distance_group,
    COUNT(*) AS station_count
FROM nearest
GROUP BY distance_group
ORDER BY MIN(distance_m);
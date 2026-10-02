WITH nearest AS (
    SELECT
        s.station_id,
        d.district_id,
        ST_Distance(s.geom, d.geom) AS distance_m
    FROM bj_life.transit_station s
    CROSS JOIN LATERAL (
        SELECT
            d.district_id,
            d.geom
        FROM bj_life.district d
        ORDER BY d.geom <-> s.geom
        LIMIT 1
    ) d
    WHERE s.district_id IS NULL
)
UPDATE bj_life.transit_station s
SET district_id = n.district_id
FROM nearest n
WHERE s.station_id = n.station_id
  AND n.distance_m > 0
  AND n.distance_m <= 100
  AND s.district_id IS NULL;
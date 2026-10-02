SELECT
    s.station_id,
    s.station_code,
    s.station_name,
    ST_X(ST_Transform(s.geom, 4326)) AS longitude,
    ST_Y(ST_Transform(s.geom, 4326)) AS latitude,
    d.district_name AS nearest_district,
    ROUND(ST_Distance(s.geom, d.geom)) AS distance_m
FROM bj_life.transit_station s
CROSS JOIN LATERAL (
    SELECT
        d.district_name,
        d.geom
    FROM bj_life.district d
    ORDER BY d.geom <-> s.geom
    LIMIT 1
) d
WHERE s.district_id IS NULL
ORDER BY distance_m DESC
LIMIT 50;
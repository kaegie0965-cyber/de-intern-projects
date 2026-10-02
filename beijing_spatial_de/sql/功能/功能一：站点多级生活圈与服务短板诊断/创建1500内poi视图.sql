CREATE OR REPLACE VIEW bj_life.v_demo_station_poi AS
WITH params AS (
    SELECT 12345::bigint AS station_id
),

station AS (
    SELECT s.*
    FROM bj_life.transit_station s
    JOIN params p
      ON s.station_id = p.station_id
),

measured AS (
    SELECT
        p.poi_id,
        p.name,
        p.address,
        c.service_class_name,

        ST_Distance(
            p.geom,
            s.geom
        ) AS distance_m,

        p.geom

    FROM station s

    JOIN bj_life.service_poi p
      ON p.geom IS NOT NULL
     AND p.geom && ST_Expand(s.geom, 1500)
     AND ST_DWithin(
            p.geom,
            s.geom,
            1500
         )

    JOIN bj_life.service_category c
      ON c.category_id = p.category_id
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY distance_m, poi_id
    )::integer AS objectid,

    poi_id,
    name,
    address,
    service_class_name,

    ROUND(
        distance_m::numeric,
        1
    ) AS distance_m,

    CASE
        WHEN distance_m <= 500
            THEN '0—500米'
        WHEN distance_m <= 1000
            THEN '500—1000米'
        ELSE '1000—1500米'
    END AS distance_band,

    geom

FROM measured;
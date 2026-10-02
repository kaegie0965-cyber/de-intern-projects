CREATE OR REPLACE VIEW
bj_life.v_demo_station_missing_nearest AS
WITH params AS (
    SELECT 12345::bigint AS station_id
),

radii(radius_m) AS (
    VALUES
        (500),
        (1000),
        (1500)
),

station AS (
    SELECT s.*
    FROM bj_life.transit_station s
    JOIN params p
      ON s.station_id = p.station_id
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY r.radius_m, c.category_id
    )::integer AS objectid,

    s.station_name,
    r.radius_m,

    c.service_class_name
        AS missing_category,

    nearest.poi_id
        AS nearest_poi_id,

    nearest.name
        AS nearest_poi_name,

    ROUND(
        nearest.distance_m::numeric,
        1
    ) AS nearest_distance_m,

    ROUND(
        GREATEST(
            nearest.distance_m - r.radius_m,
            0
        )::numeric,
        1
    ) AS beyond_radius_m,

    nearest.geom

FROM station s
CROSS JOIN radii r
CROSS JOIN bj_life.service_category c

LEFT JOIN LATERAL (
    SELECT
        p.poi_id,
        p.name,

        ST_Distance(
            p.geom,
            s.geom
        ) AS distance_m,

        p.geom

    FROM bj_life.service_poi p

    WHERE p.category_id = c.category_id
      AND p.geom IS NOT NULL

    ORDER BY p.geom <-> s.geom
    LIMIT 1
) nearest ON TRUE

WHERE NOT EXISTS (
    SELECT 1
    FROM bj_life.service_poi p
    WHERE p.category_id = c.category_id
      AND p.geom IS NOT NULL
      AND p.geom && ST_Expand(s.geom, r.radius_m)
      AND ST_DWithin(
            p.geom,
            s.geom,
            r.radius_m
          )
);
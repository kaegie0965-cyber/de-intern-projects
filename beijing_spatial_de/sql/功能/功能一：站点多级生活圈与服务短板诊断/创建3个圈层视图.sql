CREATE OR REPLACE VIEW bj_life.v_demo_station_circle AS
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
),

category_total AS (
    SELECT COUNT(*)::numeric AS total_count
    FROM bj_life.service_category
)

SELECT
    CASE r.radius_m
        WHEN 500 THEN 1
        WHEN 1000 THEN 2
        ELSE 3
    END::integer AS objectid,

    s.station_id,
    s.station_name,
    s.station_type,
    r.radius_m,

    stat.poi_count,
    stat.category_count,

    ROUND(
        (
            100.0 *
            stat.category_count /
            NULLIF(ct.total_count, 0)
        )::numeric,
        2
    ) AS completeness_percent,

    COALESCE(
        missing.missing_categories,
        '无'
    ) AS missing_categories,

    ST_Multi(
        ST_Buffer(s.geom, r.radius_m)
    )::geometry(MultiPolygon, 4509) AS geom

FROM station s
CROSS JOIN radii r
CROSS JOIN category_total ct

CROSS JOIN LATERAL (
    SELECT
        COUNT(p.poi_id)::bigint AS poi_count,
        COUNT(DISTINCT p.category_id)::bigint
            AS category_count
    FROM bj_life.service_poi p
    WHERE p.geom IS NOT NULL
      AND p.geom && ST_Expand(s.geom, r.radius_m)
      AND ST_DWithin(
            p.geom,
            s.geom,
            r.radius_m
          )
) stat

CROSS JOIN LATERAL (
    SELECT
        STRING_AGG(
            c.service_class_name,
            '、'
            ORDER BY c.category_id
        ) AS missing_categories
    FROM bj_life.service_category c
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
    )
) missing;
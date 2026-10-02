CREATE OR REPLACE VIEW bj_life.v_demo_service_candidate AS
WITH candidates AS (
    SELECT
        objectid,
        district_name,
        category_name,
        blind_area_km2,

        ST_PointOnSurface(geom)
            ::geometry(Point, 4509) AS geom

    FROM bj_life.v_demo_service_blind_spot
)

SELECT
    c.objectid,
    c.district_name,
    c.category_name,
    c.blind_area_km2,

    r.road_name AS nearest_road,

    ROUND(
        r.distance_m::numeric,
        1
    ) AS nearest_road_m,

    COUNT(p.poi_id)
        AS surrounding_poi_count,

    COUNT(DISTINCT p.category_id)
        AS surrounding_category_count,

    c.geom

FROM candidates c

LEFT JOIN LATERAL (
    SELECT
        COALESCE(
            NULLIF(road.road_name, ''),
            road.road_code,
            '未命名道路'
        )::varchar(120) AS road_name,

        ST_Distance(
            c.geom,
            road.geom
        ) AS distance_m

    FROM bj_life.road_osm_clean road

    WHERE road.geom IS NOT NULL

    ORDER BY road.geom <-> c.geom

    LIMIT 1
) r ON TRUE

LEFT JOIN bj_life.service_poi p
  ON p.geom IS NOT NULL
 AND ST_DWithin(
        p.geom,
        c.geom,
        1000
     )

GROUP BY
    c.objectid,
    c.district_name,
    c.category_name,
    c.blind_area_km2,
    r.road_name,
    r.distance_m,
    c.geom;
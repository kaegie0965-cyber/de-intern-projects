CREATE OR REPLACE VIEW bj_life.v_demo_car_route_points AS

WITH params AS (
    SELECT
        255384::bigint AS start_poi_id,  -- 清华大学
        74014::bigint AS end_poi_id      -- 颐和园
),

selected_pois AS (
    SELECT
        requested.objectid,
        requested.point_role,
        p.poi_id,
        p.name,
        p.geom

    FROM params q

    CROSS JOIN LATERAL (
        VALUES
            (
                1::integer,
                'start'::text,
                q.start_poi_id
            ),
            (
                2::integer,
                'end'::text,
                q.end_poi_id
            )
    ) requested(
        objectid,
        point_role,
        poi_id
    )

    JOIN bj_life.service_poi p
      ON p.poi_id = requested.poi_id

    WHERE p.geom IS NOT NULL
      AND NOT ST_IsEmpty(p.geom)
),

snapped_points AS (
    SELECT
        p.objectid,
        p.point_role,
        p.poi_id,
        p.name,

        nearest.id AS node_id,

        ST_Distance(
            p.geom,
            nearest.geom
        ) AS snap_distance_m,

        nearest.geom::geometry(
            Point,
            4509
        ) AS geom

    FROM selected_pois p

    CROSS JOIN LATERAL (
        SELECT
            v.id,
            v.geom

        FROM bj_life.routing_car_vertices v

        JOIN bj_life.routing_car_vertex_components vc
          ON vc.node = v.id

        WHERE vc.component = 1

        ORDER BY v.geom <-> p.geom

        LIMIT 1
    ) nearest
)

SELECT
    objectid,
    point_role,

    CASE
        WHEN point_role = 'start'
            THEN '起点：' || name
        ELSE '终点：' || name
    END AS point_label,

    poi_id,
    name,
    node_id,

    ROUND(
        snap_distance_m::numeric,
        1
    ) AS snap_distance_m,

    geom::geometry(
        Point,
        4509
    ) AS geom

FROM snapped_points;
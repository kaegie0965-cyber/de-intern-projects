WITH selected_pois AS (
    SELECT
        CASE
            WHEN p.poi_id = 256371 THEN 'start'
            WHEN p.poi_id = 76089  THEN 'end'
        END AS point_role,
        p.poi_id,
        p.name,
        p.geom
    FROM bj_life.service_poi p
    WHERE p.poi_id IN (256371, 76089)
),

snapped_points AS (
    SELECT
        p.point_role,
        p.poi_id,
        p.name,
        p.geom AS poi_geom,
        nearest.id AS node_id,
        nearest.geom AS node_geom,
        ST_Distance(p.geom, nearest.geom) AS snap_distance_m
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
),

endpoints AS (
    SELECT
        MAX(node_id) FILTER (
            WHERE point_role = 'start'
        ) AS start_node,

        MAX(node_id) FILTER (
            WHERE point_role = 'end'
        ) AS end_node
    FROM snapped_points
),

route_raw AS (
    SELECT route_result.*
    FROM endpoints ep

    CROSS JOIN LATERAL pgr_dijkstra(
        $edges$
        SELECT
            id,
            source,
            target,
            cost,
            reverse_cost
        FROM bj_life.routing_car_edges
        $edges$,

        ep.start_node,
        ep.end_node,
        true
    ) AS route_result
),

route_steps AS (
    SELECT
        r.path_seq,
        r.node,
        r.edge,
        r.cost,

        CASE
            WHEN r.node = e.source
                THEN e.geom
            ELSE ST_Reverse(e.geom)
        END AS geom

    FROM route_raw r
    JOIN bj_life.routing_car_edges e
      ON e.id = r.edge

    WHERE r.edge <> -1
),

route_result AS (
    SELECT
        COUNT(*) AS edge_count,
        SUM(cost) AS route_length_m,

        ST_MakeLine(
            geom ORDER BY path_seq
        )::geometry(LineString, 4509) AS geom

    FROM route_steps
)

SELECT
    1::integer AS objectid,

    (
        SELECT name
        FROM snapped_points
        WHERE point_role = 'start'
    ) AS start_name,

    (
        SELECT name
        FROM snapped_points
        WHERE point_role = 'end'
    ) AS end_name,

    (
        SELECT node_id
        FROM snapped_points
        WHERE point_role = 'start'
    ) AS start_node,

    (
        SELECT node_id
        FROM snapped_points
        WHERE point_role = 'end'
    ) AS end_node,

    ROUND(
        (
            SELECT snap_distance_m
            FROM snapped_points
            WHERE point_role = 'start'
        )::numeric,
        1
    ) AS start_snap_m,

    ROUND(
        (
            SELECT snap_distance_m
            FROM snapped_points
            WHERE point_role = 'end'
        )::numeric,
        1
    ) AS end_snap_m,

    route_result.edge_count,

    ROUND(
        route_result.route_length_m::numeric,
        1
    ) AS route_length_m,

    ROUND(
        (route_result.route_length_m / 1000.0)::numeric,
        2
    ) AS route_length_km,

    route_result.geom

FROM route_result;
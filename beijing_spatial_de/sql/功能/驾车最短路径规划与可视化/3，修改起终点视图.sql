CREATE OR REPLACE VIEW bj_life.v_demo_car_route AS

SELECT
    r.objectid,
    r.start_poi_id,
    r.start_name,
    r.end_poi_id,
    r.end_name,
    r.start_node,
    r.end_node,
    r.start_snap_m,
    r.end_snap_m,
    r.edge_count,
    r.route_length_m,
    r.route_length_km,

    r.geom::geometry(
        LineString,
        4509
    ) AS geom

FROM bj_life.fn_car_shortest_route(
    255384,  -- 起点：清华大学
    74014    -- 终点：颐和园
) r;
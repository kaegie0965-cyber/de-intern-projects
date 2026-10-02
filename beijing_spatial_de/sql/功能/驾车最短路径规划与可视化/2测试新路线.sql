SELECT
    start_name,
    end_name,
    start_snap_m,
    end_snap_m,
    edge_count,
    route_length_km,
    geom
FROM bj_life.fn_car_shortest_route(
    255384,
    74014
);
SELECT
    objectid,
    poi_id,
    name,
    address,
    service_class_name,
    distance_m,
    distance_band,
    geom::geometry(Point, 4509) AS geom
FROM bj_life.v_demo_station_poi
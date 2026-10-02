SELECT
    objectid,
    station_name,
    radius_m,
    missing_category,
    nearest_poi_id,
    nearest_poi_name,
    nearest_distance_m,
    beyond_radius_m,
    geom::geometry(Point, 4509) AS geom
FROM bj_life.v_demo_station_missing_nearest
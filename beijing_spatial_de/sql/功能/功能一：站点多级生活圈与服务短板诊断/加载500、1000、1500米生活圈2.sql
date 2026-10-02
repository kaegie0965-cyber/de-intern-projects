SELECT
    objectid,
    station_id,
    station_name,
    station_type,
    radius_m,
    poi_count,
    category_count,
    completeness_percent,
    missing_categories,
    geom::geometry(MultiPolygon, 4509) AS geom
FROM bj_life.v_demo_station_circle
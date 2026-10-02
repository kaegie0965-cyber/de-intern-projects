SELECT
    objectid,
    district_name,
    area_km2,
    poi_count,
    poi_density_km2,
    category_count,
    completeness_percent,
    station_count,
    station_density_km2,
    road_length_km,
    road_density_km_km2,
    service_score,
    transport_score,
    coordination_type,
    geom::geometry(MultiPolygon, 4509) AS geom
FROM bj_life.v_demo_district_coordination
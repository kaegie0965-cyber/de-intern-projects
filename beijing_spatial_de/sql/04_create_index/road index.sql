CREATE INDEX gix_road_osm_clean_geom
ON bj_life.road_osm_clean
USING GIST (geom);

CREATE INDEX idx_road_osm_clean_type
ON bj_life.road_osm_clean (road_type);

ANALYZE bj_life.road_osm_clean;
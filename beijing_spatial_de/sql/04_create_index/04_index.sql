CREATE INDEX IF NOT EXISTS gix_transit_station_geom
ON bj_life.transit_station
USING GIST (geom);

CREATE INDEX IF NOT EXISTS gix_district_geom
ON bj_life.district
USING GIST (geom);

ANALYZE bj_life.transit_station;
ANALYZE bj_life.district;
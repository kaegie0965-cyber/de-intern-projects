CREATE TABLE bj_life.stg_transit_station (
    station_id BIGINT,
    station_code VARCHAR(20),
    station_name VARCHAR(150),
    station_type VARCHAR(20),
    district_id INTEGER,
    geom geometry(Point,4326)
);
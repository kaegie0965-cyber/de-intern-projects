CREATE TABLE IF NOT EXISTS bj_life.transit_station (
    station_id BIGINT PRIMARY KEY,
    station_code VARCHAR(10) UNIQUE NOT NULL,
    station_name VARCHAR(150) NOT NULL,
    station_type VARCHAR(20) NOT NULL
        CHECK (station_type IN ('公交站', '地铁站')),
    district_id INTEGER
        REFERENCES bj_life.district(district_id),
    geom geometry(Point,4509) NOT NULL
);

SELECT COUNT(*) FROM bj_life.transit_station;
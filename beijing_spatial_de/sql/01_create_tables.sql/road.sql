CREATE TABLE bj_life.road (
    road_id BIGINT PRIMARY KEY,
    road_code VARCHAR(20) NOT NULL UNIQUE,
    road_name VARCHAR(120),
    road_type VARCHAR(50) NOT NULL,
    length_m NUMERIC(14,3) NOT NULL,
    geom geometry(MultiLineString,4509) NOT NULL,

    CONSTRAINT chk_road_length
        CHECK (length_m > 0)
);
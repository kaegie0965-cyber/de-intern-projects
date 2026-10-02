CREATE TABLE bj_life.stg_transit_line (
    line_id BIGINT,
    line_code VARCHAR(20),
    line_name VARCHAR(120),
    line_type VARCHAR(20),
    geom geometry(MultiLineString,4326)
);
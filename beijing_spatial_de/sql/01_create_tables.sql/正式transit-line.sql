CREATE TABLE bj_life.transit_line (
    line_id BIGINT PRIMARY KEY,

    line_code VARCHAR(9)
    UNIQUE NOT NULL,

    line_name VARCHAR(120)
    NOT NULL,

    line_type VARCHAR(20)
    NOT NULL,

    geom geometry(MultiLineString,4509)
    NOT NULL
);
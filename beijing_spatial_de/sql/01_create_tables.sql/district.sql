CREATE TABLE bj_life.district (
    district_id INTEGER PRIMARY KEY,
    district_code CHAR(6) NOT NULL UNIQUE,
    district_name VARCHAR(30) NOT NULL,
    geom geometry(MultiPolygon, 4509) NOT NULL
);
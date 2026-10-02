CREATE TABLE bj_life.service_poi (
    poi_id BIGINT PRIMARY KEY,
    poi_code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    sub_category VARCHAR(100),
    category_id INTEGER NOT NULL,
    address VARCHAR(255),
    district_id INTEGER NOT NULL,
    geom geometry(Point, 4509) NOT NULL,

    CONSTRAINT fk_poi_category
        FOREIGN KEY (category_id)
        REFERENCES bj_life.service_category(category_id),

    CONSTRAINT fk_poi_district
        FOREIGN KEY (district_id)
        REFERENCES bj_life.district(district_id)
);
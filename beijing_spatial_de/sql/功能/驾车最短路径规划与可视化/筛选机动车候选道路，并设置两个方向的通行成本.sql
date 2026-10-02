BEGIN;

-- 筛选机动车候选道路，并保留原道路属性
CREATE TABLE bj_life.routing_car_roads AS
SELECT
    r.*,

    -- 沿道路几何正方向：B、F允许通行
    CASE
        WHEN r.oneway IN ('B', 'F')
            THEN r.length_m
        ELSE -1::double precision
    END AS cost,

    -- 沿道路几何反方向：B、T允许通行
    CASE
        WHEN r.oneway IN ('B', 'T')
            THEN r.length_m
        ELSE -1::double precision
    END AS reverse_cost

FROM bj_life.routing_road_base r

WHERE r.road_type IN (
    'motorway',
    'motorway_link',
    'trunk',
    'trunk_link',
    'primary',
    'primary_link',
    'secondary',
    'secondary_link',
    'tertiary',
    'tertiary_link',
    'unclassified',
    'residential',
    'living_street',
    'service'
);

-- 道路唯一编号
ALTER TABLE bj_life.routing_car_roads
ADD CONSTRAINT routing_car_roads_pkey
PRIMARY KEY (road_id);

-- 空间索引
CREATE INDEX routing_car_roads_geom_gix
ON bj_life.routing_car_roads
USING GIST (geom);

ANALYZE bj_life.routing_car_roads;

COMMIT;
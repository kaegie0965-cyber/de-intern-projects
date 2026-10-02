-- 1. 行政区：空间包含、相交查询
CREATE INDEX IF NOT EXISTS gix_district_geom
ON bj_life.district
USING GIST (geom);


-- 2. 生活服务点：周边查询、分类查询、行政区统计
CREATE INDEX IF NOT EXISTS gix_service_facility_geom
ON bj_life.service_poi
USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_facility_guide_class
ON bj_life.service_poi (category_id);

CREATE INDEX IF NOT EXISTS idx_facility_district_id
ON bj_life.service_poi (district_id);


-- 3. 道路：邻近、相交和道路类型查询
CREATE INDEX IF NOT EXISTS gix_road_geom
ON bj_life.road
USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_road_type
ON bj_life.road (road_type);


-- 4. 公交、地铁线路：沿线分析和线路类型查询
CREATE INDEX IF NOT EXISTS gix_transit_line_geom
ON bj_life.transit_line
USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_transit_line_type
ON bj_life.transit_line (line_type);


-- 5. 更新统计信息，让数据库开始使用新索引
ANALYZE bj_life.district;
ANALYZE bj_life.service_category;
ANALYZE bj_life.service_poi;
ANALYZE bj_life.road;
ANALYZE bj_life.transit_line;
ANALYZE bj_life.transit_station;
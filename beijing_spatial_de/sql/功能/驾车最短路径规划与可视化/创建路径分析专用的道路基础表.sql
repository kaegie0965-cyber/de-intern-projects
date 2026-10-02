BEGIN;

-- 创建路径分析专用的道路基础表
CREATE TABLE bj_life.routing_road_base AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY r.id, r.fid
    ) AS road_id,

    r.id AS original_id,
    r.fid AS original_fid,
    r.osm_id,
    r.name AS road_name,

    LOWER(BTRIM(r.fclass)) AS road_type,
    UPPER(BTRIM(r.oneway)) AS oneway,

    r.maxspeed,
    r.layer AS osm_layer,
    UPPER(BTRIM(r.bridge)) AS bridge,
    UPPER(BTRIM(r.tunnel)) AS tunnel,

    ST_Length(r.geom) AS length_m,

    ST_Force2D(r.geom)
        ::geometry(LineString, 4509) AS geom

FROM bj_life.road_osm_new r

WHERE r.geom IS NOT NULL
  AND NOT ST_IsEmpty(r.geom)
  AND ST_IsValid(r.geom)
  AND ST_Length(r.geom) > 0;

-- 每条记录具有唯一编号
ALTER TABLE bj_life.routing_road_base
ADD CONSTRAINT routing_road_base_pkey
PRIMARY KEY (road_id);

-- 为后续空间查询建立索引
CREATE INDEX routing_road_base_geom_gix
ON bj_life.routing_road_base
USING GIST (geom);

-- 更新统计信息
ANALYZE bj_life.routing_road_base;

COMMIT;
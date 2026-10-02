-- 步骤：从共享的原有顶点重建驾车路网（PostGIS，兼容 pgRouting 4）
-- 输入：bj_life.routing_car_roads
-- 新建：routing_car_edges、routing_car_vertices、routing_car_topology_review
-- 请在 Beijing_life_db 的查询工具中整段执行一次。
-- 不对所有平面交点强制打断；不使用大容差吸附。
-- 同坐标同结构属性连接；跨结构仅当全部为原始端点时推定接续。
-- 推定的端点接续和暂时隔离的位置都会保留在核查表中。
-- 这些是根据现有几何与属性重建的规则，不是完整的 OSM 导航拓扑。
-- 若途中报错，先执行 ROLLBACK; 并查看第一条错误，不要只运行后半段。

BEGIN;

-- 1. 展开道路原有顶点，记录它在道路中的顺序和原始端点身份。
CREATE TEMP TABLE _car_p ON COMMIT DROP AS
WITH roads AS MATERIALIZED (
    SELECT
        road_id,
        COALESCE(osm_layer::text, '?') || '/' ||
        COALESCE(NULLIF(bridge, ''), '?') || '/' ||
        COALESCE(NULLIF(tunnel, ''), '?') AS struct_key,
        osm_layer IS NULL
            OR bridge IS NULL OR bridge NOT IN ('T', 'F')
            OR tunnel IS NULL OR tunnel NOT IN ('T', 'F')
            AS unknown_attributes,
        ST_NPoints(geom) AS point_count,
        geom
    FROM bj_life.routing_car_roads
)
SELECT
    r.road_id,
    d.path[1] AS pos,
    d.path[1] IN (1, r.point_count) AS is_orig_end,
    r.struct_key,
    r.unknown_attributes,
    ST_X(d.geom) AS x,
    ST_Y(d.geom) AS y,
    d.geom::geometry(Point, 4509) AS pt
FROM roads r
CROSS JOIN LATERAL ST_DumpPoints(r.geom) AS d;

ALTER TABLE _car_p ADD PRIMARY KEY (road_id, pos);
CREATE INDEX ON _car_p (x, y);
ANALYZE _car_p;

-- 2. 检查同一坐标是否被多条路或同一路的多个位置使用。
CREATE TEMP TABLE _car_xy ON COMMIT DROP AS
SELECT
    x, y,
    COUNT(*) AS occurrence_count,
    COUNT(DISTINCT road_id) AS road_count,
    BOOL_AND(is_orig_end) AS all_orig_ends,
    BOOL_OR(is_orig_end) AS has_orig_end,
    BOOL_OR(unknown_attributes) AS unknown_attributes,
    COUNT(DISTINCT struct_key) AS context_count
FROM _car_p
GROUP BY x, y;

ALTER TABLE _car_xy ADD PRIMARY KEY (x, y);
ANALYZE _car_xy;

-- 3. 节点只建立在道路端点或重复出现的兼容顶点处。
-- @ends 仅用于“所有出现均为切分前端点”的坐标。
-- 不同层级/桥隧属性的内部交叉保持分离。
CREATE TEMP TABLE _car_nodes ON COMMIT DROP AS
WITH grouped AS (
    SELECT
        p.x, p.y,
        CASE WHEN c.all_orig_ends
             THEN '@ends'
             ELSE p.struct_key
        END AS node_key
    FROM _car_p p
    JOIN _car_xy c USING (x, y)
    GROUP BY
        p.x, p.y,
        CASE WHEN c.all_orig_ends
             THEN '@ends'
             ELSE p.struct_key
        END
    HAVING COUNT(*) > 1 OR BOOL_OR(p.is_orig_end)
)
SELECT
    ROW_NUMBER() OVER (ORDER BY x, y, node_key) AS node_id,
    x, y, node_key,
    ST_SetSRID(ST_MakePoint(x, y), 4509)
        ::geometry(Point, 4509) AS geom
FROM grouped;

ALTER TABLE _car_nodes ADD PRIMARY KEY (node_id);
CREATE UNIQUE INDEX ON _car_nodes (x, y, node_key);
ANALYZE _car_nodes;

-- 4. 用顶点序号确定每条道路相邻的切分位置。
-- 不用 ST_LineLocatePoint，避免闭合道路和重复坐标定位到错误位置。
CREATE TEMP TABLE _car_cuts ON COMMIT DROP AS
SELECT
    p.road_id,
    p.pos AS from_pos,
    LEAD(p.pos) OVER w AS to_pos,
    n.node_id AS source,
    LEAD(n.node_id) OVER w AS target
FROM _car_p p
JOIN _car_xy c USING (x, y)
JOIN _car_nodes n
  ON n.x = p.x
 AND n.y = p.y
 AND n.node_key = CASE WHEN c.all_orig_ends
                       THEN '@ends'
                       ELSE p.struct_key
                  END
WINDOW w AS (PARTITION BY p.road_id ORDER BY p.pos);

ANALYZE _car_cuts;

-- 5. 按原有点序重建子路段，保持原单行方向。
-- 每个子路段重新计算自己的长度，不能沿用整条原路的长度。
CREATE TABLE bj_life.routing_car_edges AS
WITH segments AS (
    SELECT
        c.road_id, c.from_pos, c.to_pos,
        c.source, c.target,
        s.geom
    FROM _car_cuts c
    CROSS JOIN LATERAL (
        SELECT
            ST_MakeLine(p.pt ORDER BY p.pos)
                ::geometry(LineString, 4509) AS geom
        FROM _car_p p
        WHERE p.road_id = c.road_id
          AND p.pos BETWEEN c.from_pos AND c.to_pos
    ) s
    WHERE c.to_pos IS NOT NULL
),
measured AS (
    SELECT *, ST_Length(geom) AS length_m
    FROM segments
)
SELECT
    ROW_NUMBER() OVER (ORDER BY m.road_id, m.from_pos) AS id,
    m.road_id, m.from_pos, m.to_pos,
    m.source, m.target,
    r.road_name, r.road_type, r.oneway,
    r.osm_layer, r.bridge, r.tunnel, r.maxspeed,
    m.length_m,
    CASE WHEN r.oneway IN ('B', 'F')
         THEN m.length_m ELSE -1.0
    END::double precision AS cost,
    CASE WHEN r.oneway IN ('B', 'T')
         THEN m.length_m ELSE -1.0
    END::double precision AS reverse_cost,
    m.geom
FROM measured m
JOIN bj_life.routing_car_roads r USING (road_id)
WHERE m.length_m > 0;

-- 不删除正长度的 source=target 路段，它可能是合法的闭合道路。
CREATE TABLE bj_life.routing_car_vertices AS
SELECT node_id AS id, node_key, geom
FROM _car_nodes;

-- 6. 保留需要人工核查的位置，包括推定相连的跨结构端点。
CREATE TABLE bj_life.routing_car_topology_review AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.x, c.y) AS objectid,
    CASE
        WHEN c.unknown_attributes THEN 'unknown_attributes'
        WHEN c.all_orig_ends THEN 'endpoint_transition_assumed'
        ELSE 'different_structures_kept_separate'
    END AS reason,
    c.context_count,
    c.road_count,
    c.all_orig_ends,
    c.unknown_attributes,
    ARRAY_AGG(DISTINCT p.road_id) AS road_ids,
    ARRAY_AGG(DISTINCT p.struct_key) AS structures,
    ST_SetSRID(ST_MakePoint(c.x, c.y), 4509)
        ::geometry(Point, 4509) AS geom
FROM _car_xy c
JOIN _car_p p USING (x, y)
WHERE c.context_count > 1
   OR (c.unknown_attributes
       AND (c.occurrence_count > 1 OR c.has_orig_end))
GROUP BY c.x, c.y, c.context_count, c.road_count,
         c.all_orig_ends, c.unknown_attributes;

-- 7. 约束和索引。
ALTER TABLE bj_life.routing_car_vertices ADD PRIMARY KEY (id);
ALTER TABLE bj_life.routing_car_edges ADD PRIMARY KEY (id);
ALTER TABLE bj_life.routing_car_edges
    ALTER COLUMN source SET NOT NULL,
    ALTER COLUMN target SET NOT NULL,
    ADD CHECK (length_m > 0),
    ADD CHECK (cost > 0 OR reverse_cost > 0),
    ADD FOREIGN KEY (source) REFERENCES bj_life.routing_car_vertices(id),
    ADD FOREIGN KEY (target) REFERENCES bj_life.routing_car_vertices(id);

ALTER TABLE bj_life.routing_car_topology_review
    ADD PRIMARY KEY (objectid);

CREATE INDEX ON bj_life.routing_car_edges (source);
CREATE INDEX ON bj_life.routing_car_edges (target);
CREATE INDEX ON bj_life.routing_car_edges (road_id);
CREATE INDEX ON bj_life.routing_car_edges USING gist (geom);
CREATE INDEX ON bj_life.routing_car_vertices USING gist (geom);
CREATE INDEX ON bj_life.routing_car_topology_review USING gist (geom);

ANALYZE bj_life.routing_car_edges;
ANALYZE bj_life.routing_car_vertices;
ANALYZE bj_life.routing_car_topology_review;

-- 8. 自动检查：没有漏路、每条原路分段后的总长度基本不变，
-- 且子路段起终点坐标与节点字典一致。失败则本事务不会提交。
DO $routing_checks$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM bj_life.routing_car_edges) THEN
        RAISE EXCEPTION 'No routing edges were created.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM bj_life.routing_car_roads r
        LEFT JOIN (
            SELECT road_id, SUM(length_m) AS split_length
            FROM bj_life.routing_car_edges
            GROUP BY road_id
        ) e USING (road_id)
        WHERE e.split_length IS NULL
           OR ABS(e.split_length - r.length_m)
              > GREATEST(0.001, r.length_m * 1e-9)
    ) THEN
        RAISE EXCEPTION 'Road coverage/length check failed.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM bj_life.routing_car_edges e
        JOIN bj_life.routing_car_vertices s ON s.id = e.source
        JOIN bj_life.routing_car_vertices t ON t.id = e.target
        WHERE NOT ST_Equals(ST_StartPoint(e.geom), s.geom)
           OR NOT ST_Equals(ST_EndPoint(e.geom), t.geom)
    ) THEN
        RAISE EXCEPTION 'Edge endpoint/vertex check failed.';
    END IF;
END
$routing_checks$;

COMMIT;

-- 成功后最后显示这一行结果，请保存或截图。
SELECT
    (SELECT COUNT(*) FROM bj_life.routing_car_roads) AS original_roads,
    COUNT(*) AS routing_edges,
    COUNT(DISTINCT road_id) AS covered_roads,
    (SELECT COUNT(*) FROM bj_life.routing_car_vertices) AS routing_nodes,
    (SELECT COUNT(*) FROM bj_life.routing_car_topology_review) AS review_points
FROM bj_life.routing_car_edges;

BEGIN;

CREATE TABLE bj_life.routing_car_vertex_components AS
SELECT
    component,
    node
FROM pgr_connectedComponents(
    $edges$
    SELECT
        id,
        source,
        target,
        length_m::double precision AS cost
    FROM bj_life.routing_car_edges
    $edges$
);

ALTER TABLE bj_life.routing_car_vertex_components
    ADD PRIMARY KEY (node);

CREATE INDEX idx_routing_car_components_component
ON bj_life.routing_car_vertex_components (component);

ANALYZE bj_life.routing_car_vertex_components;

COMMIT;


/* 查看总体连通情况 */
WITH component_sizes AS (
    SELECT
        component,
        COUNT(*) AS node_count
    FROM bj_life.routing_car_vertex_components
    GROUP BY component
)
SELECT
    COUNT(*) AS component_count,
    SUM(node_count) AS assigned_nodes,
    MAX(node_count) AS largest_component_nodes,
    ROUND(
        100.0 * MAX(node_count) / SUM(node_count),
        2
    ) AS largest_component_percent
FROM component_sizes;


/* 查看节点数量最多的前10个连通分量 */
SELECT
    component,
    COUNT(*) AS node_count,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS node_percent
FROM bj_life.routing_car_vertex_components
GROUP BY component
ORDER BY node_count DESC
LIMIT 10;
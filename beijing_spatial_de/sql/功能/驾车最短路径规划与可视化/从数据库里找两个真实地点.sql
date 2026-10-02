WITH keywords(keyword, sort_order) AS (
    VALUES
        ('北京大学', 1),
        ('清华大学', 2),
        ('故宫', 3),
        ('天安门', 4),
        ('颐和园', 5),
        ('北京站', 6),
        ('北京南站', 7)
),

candidate_pois AS (
    SELECT
        k.sort_order,
        k.keyword,
        p.poi_id,
        p.name,
        p.address,
        p.district_id,
        p.category_id,
        p.geom
    FROM keywords k
    CROSS JOIN LATERAL (
        SELECT
            p.*
        FROM bj_life.service_poi p
        WHERE p.geom IS NOT NULL
          AND NOT ST_IsEmpty(p.geom)
          AND p.name ILIKE '%' || k.keyword || '%'
        ORDER BY
            CASE WHEN p.name = k.keyword THEN 0 ELSE 1 END,
            p.poi_id
        LIMIT 5
    ) p
)

SELECT
    cp.keyword,
    cp.poi_id,
    cp.name,
    d.district_name,
    c.service_class_name,
    cp.address,

    nearest.id AS nearest_node,

    ROUND(
        ST_Distance(
            cp.geom,
            nearest.geom
        )::numeric,
        1
    ) AS snap_distance_m

FROM candidate_pois cp

LEFT JOIN bj_life.district d
  ON d.district_id = cp.district_id

LEFT JOIN bj_life.service_category c
  ON c.category_id = cp.category_id

CROSS JOIN LATERAL (
    SELECT
        v.id,
        v.geom
    FROM bj_life.routing_car_vertices v
    JOIN bj_life.routing_car_vertex_components vc
      ON vc.node = v.id
    WHERE vc.component = 1
    ORDER BY v.geom <-> cp.geom
    LIMIT 1
) nearest

ORDER BY
    cp.sort_order,
    snap_distance_m,
    cp.poi_id;
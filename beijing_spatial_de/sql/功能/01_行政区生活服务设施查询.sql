SELECT
    p.poi_id AS objectid,
    p.name,
    p.sub_category,
    p.address,
    c.service_class_name,
    d.district_name,
    p.geom::geometry(Point, 4509) AS geom
FROM bj_life.service_poi p
JOIN bj_life.service_category c
  ON c.category_id = p.category_id
JOIN bj_life.district d
  ON d.district_id = p.district_id
WHERE d.district_name = '海淀区'
  AND c.service_class_name = '医疗健康'
  AND p.geom IS NOT NULL
  AND NOT ST_IsEmpty(p.geom)
SELECT
    poi_id,
    name,
    address
FROM bj_life.service_poi
WHERE name ILIKE '%颐和园%'
ORDER BY
    CASE WHEN name = '颐和园' THEN 0 ELSE 1 END,
    poi_id;
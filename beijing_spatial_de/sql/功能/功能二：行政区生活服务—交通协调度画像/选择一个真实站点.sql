SELECT row_number() over () AS _uid_,* FROM (SELECT     station_id,     station_name,     station_type FROM bj_life.transit_station WHERE geom IS NOT NULL   AND NOT ST_IsEmpty(geom) ORDER BY station_id LIMIT 30
) AS _subq_1_

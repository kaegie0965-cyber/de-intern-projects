SELECT row_number() over () AS _uid_,* FROM (SELECT     p.poi_id::integer AS objectid,     p.name,     ST_Multi(         ST_Buffer(p.geom, 1000)     )::geometry(MultiPolygon, 4509) AS geom FROM bj_life.service_poi p WHERE p.poi_id = 12345
) AS _subq_1_

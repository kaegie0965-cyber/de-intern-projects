SELECT row_number() over () AS _uid_,* FROM (SELECT     1::integer AS objectid,     line_id,     line_name,     line_type,     ST_Multi(geom)::geometry(MultiLineString, 4509) AS geom FROM bj_life.transit_line WHERE line_id = 25
) AS _subq_1_

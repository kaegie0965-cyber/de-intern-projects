INSERT INTO bj_life.transit_line
(
line_id,
line_code,
line_name,
line_type,
geom
)

SELECT
line_id,
LEFT(line_code,9),
line_name,
line_type,

ST_Transform(
    geom,
    4509
)

FROM bj_life.stg_transit_line;
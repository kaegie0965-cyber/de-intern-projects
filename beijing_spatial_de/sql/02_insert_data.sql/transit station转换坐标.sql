INSERT INTO bj_life.transit_station (
    station_id,
    station_code,
    station_name,
    station_type,
    geom
)
SELECT
    station_id,
    station_code,
    station_name,
    station_type,
    ST_Transform(geom, 4509)
FROM bj_life.stg_transit_station;
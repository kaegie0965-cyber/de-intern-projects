CREATE TABLE bj_life.road_osm_clean (
    road_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    road_code VARCHAR(20) UNIQUE NOT NULL,
    road_name VARCHAR(120),
    road_type VARCHAR(50) NOT NULL,
    length_m  NUMERIC(14,2) NOT NULL CHECK (length_m >= 0),
    geom      geometry(MultiLineString, 4509) NOT NULL
);

WITH normalized AS (
    SELECT
        osm_id,
        name,
        fclass,
        ST_Multi(
            ST_CollectionExtract(
                ST_MakeValid(ST_Force2D(geom)),
                2
            )
        )::geometry(MultiLineString, 4509) AS geom
    FROM bj_life.road_osm_new
    WHERE geom IS NOT NULL
),
numbered AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY osm_id, name NULLS LAST
        ) AS rn,
        name,
        fclass,
        geom
    FROM normalized
    WHERE NOT ST_IsEmpty(geom)
)
INSERT INTO bj_life.road_osm_clean (
    road_code,
    road_name,
    road_type,
    length_m,
    geom
)
SELECT
    'R' || LPAD(rn::text, 8, '0'),
    NULLIF(name, ''),
    CASE
        WHEN fclass IN ('motorway', 'motorway_link')
            THEN '高速公路'
        WHEN fclass IN ('trunk', 'trunk_link')
            THEN '城市快速路'
        WHEN fclass IN ('primary', 'primary_link')
            THEN '主干路'
        WHEN fclass IN ('secondary', 'secondary_link')
            THEN '次干路'
        WHEN fclass IN ('tertiary', 'tertiary_link')
            THEN '支路'
        WHEN fclass IN (
            'residential',
            'living_street',
            'unclassified',
            'service'
        )
            THEN '一般道路'
        WHEN fclass LIKE 'track%'
            THEN '乡村道路'
        WHEN fclass IN (
            'cycleway',
            'footway',
            'path',
            'pedestrian',
            'steps',
            'bridleway'
        )
            THEN '慢行道路'
        ELSE COALESCE(fclass, '其他')
    END,
    ROUND(ST_Length(geom)::numeric, 2),
    geom
FROM numbered;
CREATE OR REPLACE VIEW bj_life.v_demo_service_blind_spot AS
WITH params AS (
    SELECT
        '海淀区'::text AS district_name,
        '医疗健康'::text AS category_name,
        1000.0::double precision AS radius_m
),

target AS (
    SELECT
        d.district_id,
        d.district_name,
        d.geom,
        c.category_id,
        c.service_class_name::text AS category_name,
        p.radius_m
    FROM params p
    JOIN bj_life.district d
      ON d.district_name = p.district_name
    JOIN bj_life.service_category c
      ON c.service_class_name = p.category_name
),

service_coverage AS (
    SELECT
        t.district_id,

        ST_UnaryUnion(
            ST_Collect(
                ST_Buffer(
                    p.geom,
                    t.radius_m
                )
            )
        ) AS geom

    FROM target t

    LEFT JOIN bj_life.service_poi p
      ON p.category_id = t.category_id
     AND p.geom IS NOT NULL
     AND p.geom && ST_Expand(t.geom, t.radius_m)
     AND ST_DWithin(
            p.geom,
            t.geom,
            t.radius_m
         )

    GROUP BY t.district_id
),

blind_area AS (
    SELECT
        t.district_name,
        t.category_name,
        t.radius_m,

        ST_Area(t.geom) AS district_area_m2,

        ST_CollectionExtract(
            ST_MakeValid(
                ST_Difference(
                    t.geom,
                    COALESCE(
                        c.geom,
                        ST_GeomFromText(
                            'POLYGON EMPTY',
                            4509
                        )
                    )
                )
            ),
            3
        ) AS geom

    FROM target t

    LEFT JOIN service_coverage c
      ON c.district_id = t.district_id
),

blind_parts AS (
    SELECT
        b.district_name,
        b.category_name,
        b.radius_m,
        b.district_area_m2,

        ST_Area(b.geom)
            AS total_blind_area_m2,

        ST_Force2D(dp.geom)
            ::geometry(Polygon, 4509) AS geom

    FROM blind_area b

    CROSS JOIN LATERAL
        ST_Dump(b.geom) AS dp
),

filtered_parts AS (
    SELECT *
    FROM blind_parts
    WHERE NOT ST_IsEmpty(geom)

      -- 只保留面积大于0.1平方千米的盲区
      AND ST_Area(geom) >= 100000
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            ST_Area(geom) DESC,
            ST_XMin(ST_Envelope(geom)),
            ST_YMin(ST_Envelope(geom))
    )::integer AS objectid,

    district_name,
    category_name,
    radius_m,

    ROUND(
        (
            ST_Area(geom) /
            1000000.0
        )::numeric,
        3
    ) AS blind_area_km2,

    ROUND(
        (
            100.0 *
            (
                1.0 -
                total_blind_area_m2 /
                NULLIF(district_area_m2, 0)
            )
        )::numeric,
        2
    ) AS coverage_percent,

    geom

FROM filtered_parts;
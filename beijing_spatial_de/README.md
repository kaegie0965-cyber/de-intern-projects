# Beijing Spatial Data Engineering Project
## Project Overview
This project builds a spatial data warehouse based on Beijing POI and road network data, using PostGIS + Python to implement the whole ETL pipeline.
Raw spatial data is cleaned, coordinate unified, imported into PostgreSQL, then perform spatial query, spatial index optimization and POI accessibility analysis.
This project combines GIS knowledge with data engineering, for Data Engineer internship application.

## Tech Stack
Python | Pandas | GeoPandas | PostgreSQL | PostGIS | SQL

## Workflow
1. Data Acquisition: Beijing POI dataset & city road network dataset
2. ETL: Raw data load, dirty data filter, coordinate system conversion
3. Data Storage: Store spatial geometry data in PostGIS
4. Optimization: Build spatial index to accelerate spatial neighbour query
5. Spatial Analysis: Use ST_DWithin to calculate POI proximity to roads, aggregate regional POI density
6. Output: Accessibility metrics for business analysis

## Core Scripts
- sql/01_create_tables.sql : create table with PostGIS geometry column
- sql/02_insert_data.sql : data insert
- sql/03_coordinate_transform.sql : EPSG coordinate transformation
- sql/04_create_index/ : spatial & btree index creation
- sql/05-点匹配/ : point-road spatial matching
- sql/功能/ : spatial aggregation & business statistics
- etl/etl_poi_road.py : Python ETL pipeline

## Key Challenges & Solutions
1. Mixed coordinate system in raw POI data
> Solution: Unify all geometry to EPSG:4509 via ST_Transform in PostGIS.
2. Slow query on large spatial table
> Solution: Create GIST spatial index on geometry column, query speed improved greatly.
3. Invalid geometry in raw spatial data
> Solution: Use ST_MakeValid to fix broken geometry during ETL.

## Project Output
Regional POI density table, POI-road proximity dataset, accessibility statistics.

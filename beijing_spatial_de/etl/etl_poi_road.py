import geopandas as gpd
import pandas as pd
from sqlalchemy import create_engine
from geoalchemy2 import Geometry

# -------------------------- Config --------------------------
# postgres connection, replace your username/password/dbname
DB_URI = "postgresql://username:password@localhost:5432/spatial_db"
POI_RAW_PATH = "./data/sample_data/poi_sample.geojson"
ROAD_RAW_PATH = "./data/sample_data/road_sample.geojson"

engine = create_engine(DB_URI)

def clean_spatial_data(gdf:gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    # 清洗无效几何
    gdf = gdf[gdf.is_valid]
    gdf["geometry"] = gdf["geometry"].make_valid()
    # 剔除空几何
    gdf = gdf[~gdf.is_empty]
    # 统一投影
    gdf = gdf.to_crs(epsg=4509)
    return gdf

def load_to_postgis(gdf:gpd.GeoDataFrame, table_name:str):
    gdf.to_postgis(
        name=table_name,
        con=engine,
        if_exists="append",
        index=False
    )

if __name__ == "__main__":
    print("Start ETL for POI data")
    gdf_poi = gpd.read_file(POI_RAW_PATH)
    gdf_poi_clean = clean_spatial_data(gdf_poi)
    load_to_postgis(gdf_poi_clean, "stg_beijing_poi")

    print("Start ETL for road data")
    gdf_road = gpd.read_file(ROAD_RAW_PATH)
    gdf_road_clean = clean_spatial_data(gdf_road)
    load_to_postgis(gdf_road_clean, "stg_beijing_road")

    print("ETL finished")

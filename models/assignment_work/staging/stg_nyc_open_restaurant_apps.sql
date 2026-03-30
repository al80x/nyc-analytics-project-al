-- Clean and standardize nyc restaurant application request data
-- One row per application request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
          objectid,
          globalid,
          restaurant_name,  
          legal_business_name,
          doing_business_as_dba,
          bulding_number,  
          street,  
          borough,  
          zip,  
          business_address,  
          sidewalk_dimensions_length,
          sidewalk_dimensions_width, 
          sidewalk_dimensions_area,
          roadway_dimensions_length,  
          roadway_dimensions_width,
          roadway_dimensions_area,
          time_of_submission,  
          latitude,  
          longitude
       ),

       -- Identifiers
       CAST(globalid AS STRING) AS global_id,
       CAST(objectid AS STRING) AS object_id,

       -- Date/Time
       CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,
       
       -- Request details
       CAST(restaurant_name AS STRING) AS restaurant_name,
       CAST(legal_business_name AS STRING) AS legal_business_name,
       CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,

       -- Dimensions
       CAST(sidewalk_dimensions_length AS INT) AS sidewalk_dimensions_length,
       CAST(sidewalk_dimensions_width AS INT) AS sidewalk_dimensions_width,
       CAST(sidewalk_dimensions_area AS INT) AS sidewalk_dimensions_area,
       CAST(roadway_dimensions_length AS INT) AS roadway_dimensions_length,
       CAST(roadway_dimensions_width AS INT) AS roadway_dimensions_width,
       CAST(roadway_dimensions_area AS INT) AS roadway_dimensions_area,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       --  standardizing building number
       CASE
           WHEN UPPER(TRIM(CAST(bulding_number AS STRING))) = 'UNDEFINED' THEN NULL
       END AS building_number,

       CAST(business_address AS STRING) AS business_address,
       CAST(street AS STRING) AS street,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE globalid IS NOT NULL
   AND time_of_submission IS NOT NULL
--   AND CAST(time_of_submission AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)
   AND borough IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY globalid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table: stg_nyc_open_restaurant_apps

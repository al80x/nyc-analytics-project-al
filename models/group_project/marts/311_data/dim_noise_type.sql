-- Noise type dimension for 311 reports
WITH noise_types AS (
    SELECT DISTINCT
      TRIM(SUBSTRING(complaint_type, POSITION("-" IN complaint_type), LEN(complaint_type) - POSITION("-" IN complaint_type))) AS problem_type, --TODO split problem_type into beginning portion (characters before - (consider spacing))
      CONCAT(descriptor, " ", descriptor_2) AS descriptor,
      open_data_channel_type AS source_type

   FROM {{ ref('stg_nyc_311_dot') }}    --TODO: reference the appropriate staging table!
   WHERE complaint_type IS NOT NULL

),

noise_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key([    
           'seating_interest',
           'approved_for_sidewalk',
           'approved_for_roadway'
       ]) }} AS noise_type_key, -- TODO: figure out how to generate int surrogate key
       problem_type,
       descriptor,
       source_type

   FROM noise_types
)

SELECT * FROM noise_dimension
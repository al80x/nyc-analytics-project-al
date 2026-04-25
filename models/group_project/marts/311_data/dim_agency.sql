-- Agency dimension for 311 reports
WITH agency_types AS (
   SELECT DISTINCT
       TRIM(CAST(agency_name AS STRING) AS agency_name,
       TRIM(CAST(agency AS STRING) AS agency_type
        
   FROM {{ ref('stg_nyc_311_noise') }}
   WHERE agency IS NOT NULL
),

agency_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key([
           'agency_name',
           'agency_type'
       ]) }} AS agency_key, -- TODO: figure out how to generate int surrogate key
       agency_name,
       agency_type

   FROM agency_types
)

SELECT * FROM agency_dimension
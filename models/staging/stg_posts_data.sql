WITH mentions_data AS (
    SELECT
        CAST(date_post AS DATE) AS date_only,  -- Conversion simple de STRING en DATE
        sentiment_global,                           
        volume_mentions                             
    FROM {{ source('data_carttrend', 'Carttrend_Posts') }}
)

-- Agrégation des mentions par jour
SELECT
    date_only,
    sentiment_global,
    SUM(volume_mentions) AS total_mentions
FROM mentions_data
GROUP BY
    date_only, sentiment_global
ORDER BY
    total_mentions DESC


-- Comptage des mentions par sentiment : Calculer le nombre de mentions pour chaque type de sentiment
-- Agrégation par jour 
-- Volume total des mentions
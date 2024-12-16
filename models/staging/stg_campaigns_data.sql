WITH raw_data AS (
    SELECT
        id_campagne,
        date,
        'événement_oui_non' AS evenement_oui_non,
        'événement_type' AS evenement_type,
        canal,
        budget,
        impressions,
        clics,
        conversions,
        CTR
    FROM {{ source('data_carttrend', 'Carttrend_Campaigns') }}  
    WHERE canal IS NOT NULL  -- Filtrage pour ne pas prendre en compte les lignes sans canal
)

-- Nettoyage et transformation des données
SELECT
    id_campagne,
    date,
    evenement_oui_non,
    evenement_type,
    canal,
    budget,
    -- Assurer que les valeurs numériques sont bien formatées et non nulles
    CASE 
        WHEN impressions < 0 THEN 0
        ELSE impressions
    END AS clean_impressions,
    
    CASE 
        WHEN clics < 0 THEN 0
        ELSE clics
    END AS clean_clics,
    
    CASE 
        WHEN conversions < 0 THEN 0
        ELSE conversions
    END AS clean_conversions,
    
    CASE 
        WHEN CTR < 0 THEN 0
        ELSE CTR
    END AS clean_CTR,
    
    -- Formatage de la date 
    DATE(date) AS campaign_date  -- Ici on renomme la colonne `date` en `campaign_date`
FROM raw_data

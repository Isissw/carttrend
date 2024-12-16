WITH raw_data AS (
    -- Nettoyage des données de la table Promotions
    SELECT 
        id_promotion,
        id_produit,
        type_promotion,
        valeur_promotion, 
        -- Nettoyage et conversion de la valeur de la promotion
        SAFE_CAST(REPLACE(REPLACE(valeur_promotion, ',', '.'), '%', '') AS FLOAT64) AS valeur_promotion_float,
        `date_début`,
        date_fin,
        responsable_promotion
    FROM {{ source('data_carttrend', 'Carttrend_Promotions') }}
)
-- Sélection des données nettoyées, sans erreur de LIMIT
SELECT
    id_promotion,
    id_produit,
    type_promotion,
    valeur_promotion,
    valeur_promotion_float,
    `date_début`,
    date_fin,
    responsable_promotion
FROM raw_data



-- Change les valeurs de la colonnes valeur_promotion en decimal 
-- Joindre les promotions avec les produits et les commandes
-- Comparer les ventes avec ou sans promotion
-- Analyser la réponse des produits aux promotions
-- Ration des ventes avec ou sans promotions 
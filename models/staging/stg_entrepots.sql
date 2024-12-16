WITH base AS (
    SELECT
        `id_entrepôt`,                         
        `localisation`,                         
        `capacité_max`,                         
        `volume_stocké`,                         
        `état_machine`,                             
        `température_moyenne_entrepôt`                          
    FROM {{ source('data_carttrend', 'Carttrend_Entrepots') }}
)

-- Sélection sans la colonne de date
SELECT
    `id_entrepôt`,                         
    `localisation`,                         
    `capacité_max`,                         
    `volume_stocké`,                         
    `état_machine`,                             
    `température_moyenne_entrepôt`
FROM base

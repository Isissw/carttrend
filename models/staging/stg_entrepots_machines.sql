WITH base AS (
    SELECT
        id,                         
        id_machine,                         
        `id_entrepôt`,                         
        type_machine,                         
        `état_machine`,                             
        `temps_d’arrêt`,  
        `volume_traité`,                        
        mois  
    FROM {{ source('data_carttrend', 'Carttrend_Entrepots_Machines') }}
)

-- Sélection correcte sans la colonne de date
SELECT
    id,
    id_machine,
    `id_entrepôt`,
    type_machine,
    `état_machine`,
    `temps_d’arrêt`,
    `volume_traité`,
    mois
FROM base

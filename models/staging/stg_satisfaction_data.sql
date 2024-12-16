WITH base AS (
    SELECT
        id_satisfaction,                    
        id_commande,                         
        note_client,                         
        commentaire,                         
        plainte,                             
        `temps_réponse_support`,  
        type_plainte,                        
        `employé_support`  
    FROM {{ source('data_carttrend', 'Carttrend_Satisfaction') }}
)

-- Sélection correcte sans la colonne de date
SELECT
    id_satisfaction,
    id_commande,
    note_client,
    commentaire,
    plainte,
    `temps_réponse_support`,
    type_plainte,
    `employé_support`
FROM base



-- La moyenne des notes de satisfaction des clients
-- Le nombre total de plaintes enregistrées ce jour-là.
-- La moyenne des temps de réponse du support client en heures.
-- Le nombre total de commandes livrées ce jour-là.
-- Le nombre unique de commandes livrées

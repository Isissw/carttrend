-- QUELS entrepôts traitent les plus gros volumes
WITH entrepot_taille AS (
    SELECT 
        e.`id_entrepôt`, 
        e.localisation, 
        e.`capacité_max`, 
        e.`volume_stocké`,
        e.taux_remplissage
    FROM {{ source('data_carttrend', 'Carttrend_Entrepots') }} e
    ORDER BY e.`volume_stocké` DESC
    LIMIT 100  -- Ajout de LIMIT ici
)
SELECT *
FROM entrepot_taille


-- CEUX qui causent des retards (avec information sur les entrepôts)
WITH retards_par_entrepot AS (
    SELECT 
        c.`id_entrepôt_départ`, 
        e.localisation,
        AVG(DATEDIFF(c.`date_livraison_estimée`, c.date_commande)) AS retard_moyen
    FROM {{ ref('stg_commandes_data') }} c
    JOIN {{ source('data_carttrend', 'Carttrend_Entrepots') }} e 
        ON c.`id_entrepôt_départ` = e.id_entrepot
    WHERE c.statut_commande = 'Livrée'
    GROUP BY c.`id_entrepôt_départ`, e.localisation
    ORDER BY retard_moyen DESC
    LIMIT 100  -- Ajout de LIMIT ici
)
SELECT *
FROM retards_par_entrepot


-- Répartition des tâches de commandes entre les entrepôts (charge de travail)
WITH repartition_charge AS (
    SELECT 
        c.`id_entrepôt_départ`,
        e.localisation,
        COUNT(*) AS nombre_commandes,
        SUM(c.volume_commande) AS volume_total
    FROM {{ ref('stg_commandes_data') }} c
    JOIN {{ source('data_carttrend', 'Carttrend_Entrepots') }} e 
        ON c.`id_entrepôt_départ` = e.id_entrepot
    GROUP BY c.`id_entrepôt_départ`, e.localisation
    ORDER BY volume_total DESC
    LIMIT 100  -- Ajout de LIMIT ici
)
SELECT *
FROM repartition_charge


-- Impact des machines sur la performance des entrepôts (temps d'arrêt)
WWITH impact_machines AS (
    SELECT 
        m.`id_entrepôt`,
        e.localisation,
        m.id_machine,
        m.type_machine,
        m.`état_machine`,
        m.`temps_arrêt`,
        m.`volume_traité`
    FROM {{ source('data_carttrend', 'Carttrend_Entrepots_Machines') }} m
    JOIN {{ source('data_carttrend', 'Carttrend_Entrepots') }} e 
        ON m.`id_entrepôt` = e.`id_entrepôt`
    WHERE m.`état_machine` = 'En panne'
)
SELECT *
FROM impact_machines


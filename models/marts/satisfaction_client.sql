-- 1. Extraction des données de commandes (avec retard et erreurs de livraison)
WITH commandes_data AS (
    SELECT
        c.`id_commande`,
        c.`id_client`,
        c.`id_entrepôt_départ`,
        c.`date_commande`,
        c.`statut_commande`,
        c.`date_livraison_estimée`,
        -- Calcul du retard : si la commande est livrée après la date estimée
        CASE 
            WHEN c.`statut_commande` = 'Livrée' 
                 AND c.`date_livraison_estimée` < CURRENT_DATE THEN 1  -- Retard si la livraison est après la date estimée
            ELSE 0  -- Pas de retard
        END AS `retard`,
        -- Identification des erreurs de livraison (commandes annulées)
        CASE
            WHEN c.`statut_commande` = 'Annulée' THEN 1  -- Erreur si la commande est annulée
            ELSE 0
        END AS `erreur_livraison`
    FROM 
        {{ source('data_carttrend', 'Carttrend_Commandes') }} c
    WHERE
        c.`statut_commande` IN ('Livrée', 'En transit', 'Validée')  -- Seules les commandes validées ou livrées sont concernées
),

-- 2. Notes des clients : Calcul de la note moyenne par commande
notes_clients AS (
    SELECT
        n.`id_commande`,
        AVG(n.`note_client`) AS `note_moyenne`
    FROM
        {{ source('data_carttrend', 'Carttrend_Satisfaction') }} n
    GROUP BY
        n.`id_commande`
),

-- 3. Joindre toutes les informations relatives aux commandes (retard, erreur de livraison, et notes)
commandes_avec_satisfaction AS (
    SELECT
        c.`id_commande`,
        c.`retard`,
        c.`erreur_livraison`,
        n.`note_moyenne`
    FROM 
        commandes_data c
    LEFT JOIN
        notes_clients n ON c.`id_commande` = n.`id_commande`
),

-- 4. Analyse des commandes avec et sans retard/erreur (moyenne des notes pour chaque groupe)
satisfaction_par_retard_erreur AS (
    SELECT
        `retard`,
        `erreur_livraison`,
        AVG(`note_moyenne`) AS `note_moyenne_avg`,
        COUNT(`id_commande`) AS `nb_commandes`
    FROM
        commandes_avec_satisfaction
    GROUP BY
        `retard`, `erreur_livraison`
),

-- 5. Ventes avec et sans promotion (ajout de la colonne retard et erreur_livraison dans cette CTE)
ventes_promotion AS (
    SELECT
        p.`ID` AS `id_produit`,  -- Utiliser `ID` pour la table Carttrend_Produits
        p.`Produit` AS `produit_nom`,
        COUNT(dc.`id_commande`) AS `nb_commandes`,
        SUM(dc.`quantité` * p.`Prix`) AS `total_ventes`,
        SUM(CASE WHEN pa.`id_promotion` IS NOT NULL THEN dc.`quantité` * p.`Prix` ELSE 0 END) AS `ventes_avec_promotion`,
        SUM(CASE WHEN pa.`id_promotion` IS NULL THEN dc.`quantité` * p.`Prix` ELSE 0 END) AS `ventes_sans_promotion`,
        CASE 
            WHEN SUM(CASE WHEN pa.`id_promotion` IS NOT NULL THEN dc.`quantité` * p.`Prix` ELSE 0 END) = 0 
                 AND SUM(CASE WHEN pa.`id_promotion` IS NULL THEN dc.`quantité` * p.`Prix` ELSE 0 END) = 0 THEN NULL
            WHEN SUM(CASE WHEN pa.`id_promotion` IS NULL THEN dc.`quantité` * p.`Prix` ELSE 0 END) = 0 THEN NULL
            ELSE (SUM(CASE WHEN pa.`id_promotion` IS NOT NULL THEN dc.`quantité` * p.`Prix` ELSE 0 END) / 
                  SUM(CASE WHEN pa.`id_promotion` IS NULL THEN dc.`quantité` * p.`Prix` ELSE 0 END)) - 1
        END AS `augmentation_ventes`,
        c.`retard`,  -- Ajouter la colonne retard dans cette CTE
        c.`erreur_livraison`  -- Ajouter la colonne erreur_livraison dans cette CTE
    FROM 
        {{ source('data_carttrend', 'Carttrend_Details_Commandes') }} dc
    LEFT JOIN 
        {{ source('data_carttrend', 'Carttrend_Produits') }} p ON dc.`id_produit` = p.`ID`  -- Jointure avec Carttrend_Produits
    LEFT JOIN 
        {{ source('data_carttrend', 'Carttrend_Promotions') }} pa ON p.`ID` = pa.`id_produit`  -- Jointure avec Carttrend_Promotions
    LEFT JOIN
        commandes_data c ON dc.`id_commande` = c.`id_commande`  -- Ajouter la jointure avec commandes_data pour récupérer le retard et l'erreur_livraison
    GROUP BY 
        p.`ID`, p.`Produit`, c.`retard`, c.`erreur_livraison`  -- Ajouter `retard` et `erreur_livraison` dans le GROUP BY
),

-- 6. Analyse des notes produits : Moyenne des notes des produits
notes_par_produit AS (
    SELECT 
        p.`ID` AS `id_produit`,  -- Utiliser `ID` pour la table Carttrend_Produits
        p.`Produit` AS `produit_nom`,
        AVG(s.`note_client`) AS `note_moyenne`,  -- Moyenne des notes des clients
        COUNT(s.`id_satisfaction`) AS `nb_avis`  -- Nombre d'avis sur ce produit
    FROM 
        {{ source('data_carttrend', 'Carttrend_Details_Commandes') }} dc  -- Alias pour Carttrend_Details_Commandes
    JOIN
        {{ source('data_carttrend', 'Carttrend_Satisfaction') }} s  -- Alias pour Carttrend_Satisfaction
        ON dc.`id_commande` = s.`id_commande`  -- Jointure avec Carttrend_Satisfaction sur id_commande
    JOIN 
        {{ source('data_carttrend', 'Carttrend_Produits') }} p  -- Alias pour Carttrend_Produits
        ON dc.`id_produit` = p.`ID`  -- Jointure avec Carttrend_Produits
    GROUP BY 
        p.`ID`, p.`Produit`
),

-- 7. Evolution des notes au fil du temps (par mois et par produit)
evolution_notes AS (
    SELECT 
        EXTRACT(YEAR FROM c.`date_commande`) AS `annee`,  -- Utilisation de la date_commande de Carttrend_Commandes
        EXTRACT(MONTH FROM c.`date_commande`) AS `mois`,  -- Utilisation de la date_commande de Carttrend_Commandes
        dc.`id_produit`,  -- Utiliser id_produit de Carttrend_Details_Commandes
        p.`Produit` AS `produit_nom`,
        AVG(n.`note_client`) AS `note_moyenne`
    FROM 
        {{ source('data_carttrend', 'Carttrend_Satisfaction') }} n
    JOIN
        {{ source('data_carttrend', 'Carttrend_Details_Commandes') }} dc 
        ON n.`id_commande` = dc.`id_commande`  -- Joindre Carttrend_Satisfaction à Carttrend_Details_Commandes via id_commande
    JOIN 
        {{ source('data_carttrend', 'Carttrend_Produits') }} p 
        ON dc.`id_produit` = p.`ID`  -- Joindre Carttrend_Details_Commandes à Carttrend_Produits via id_produit
    JOIN 
        {{ source('data_carttrend', 'Carttrend_Commandes') }} c
        ON n.`id_commande` = c.`id_commande`  -- Joindre Carttrend_Satisfaction à Carttrend_Commandes via id_commande
    GROUP BY 
        `annee`, `mois`, dc.`id_produit`, p.`Produit`
    ORDER BY 
        `annee` DESC, `mois` DESC
)

-- 9. Combine toutes les analyses dans un seul résultat
SELECT 
    vp.`id_produit`,
    vp.`produit_nom`,
    vp.`nb_commandes`,
    vp.`total_ventes`,
    vp.`ventes_avec_promotion`,
    vp.`ventes_sans_promotion`,
    vp.`augmentation_ventes`,
    np.`note_moyenne` AS `note_moyenne_produit`,
    np.`nb_avis` AS `nb_avis_produit`,
    en.`note_moyenne` AS `note_moyenne_evolution`,
    sr.`retard`,
    sr.`erreur_livraison`,
    sr.`note_moyenne_avg`,
    sr.`nb_commandes` AS `nb_commandes_satisfaction`
FROM 
    ventes_promotion vp
LEFT JOIN
    notes_par_produit np ON vp.`id_produit` = np.`id_produit`
LEFT JOIN
    evolution_notes en ON vp.`id_produit` = en.`id_produit`
LEFT JOIN
    satisfaction_par_retard_erreur sr ON sr.`retard` = vp.`retard` AND sr.`erreur_livraison` = vp.`erreur_livraison`
ORDER BY 
    vp.`total_ventes` DESC, np.`note_moyenne` DESC




-- -----  Analyse des ventes avec et sans promotion, pour mesurer l'impact des promotions sur les ventes.
-- Produits les mieux notés
-- note moyenne qui evolue au fil du temps 
-- Si une commande a un statut_commande de "Livrée"
-- et que la date_livraison_estimée est déjà passée (c'est-à-dire que date_livraison_estimée < aujourd'hui), alors elle est marquée comme étant en retard (avec retard = 1).
-- Nous récupérons les notes moyennes des clients pour chaque commande. Si chaque commande a plusieurs notes ou évaluations, nous calculons la moyenne des notes par commande.
-- calcule la moyenne des notes de satisfaction pour chaque groupe de commandes : 
-- celles avec ou sans retard et celles avec ou sans erreur de livraison. Elle calcule également le nombre de commandes dans chaque groupe.
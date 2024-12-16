-- Produits stars et Produits qui trainent
WITH ventes_par_produit AS (
    SELECT 
        p.ID AS id_produit,
        p.Produit,
        SUM(d.`quantité`) AS total_quantite_vendue
    FROM 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p ON d.id_produit = p.ID
    GROUP BY 
        p.ID, p.Produit
)
-- Liste des produits populaires et ceux qui trainent 
SELECT 
    id_produit, 
    Produit,
    total_quantite_vendue
FROM 
    ventes_par_produit
ORDER BY 
    total_quantite_vendue DESC;

-- Identifier les categories les plus génératrices de revenus et les catégories en déclin
WITH ventes_par_categorie AS (
    SELECT 
        p.`Catégorie`,  
        SUM(d.`quantité` * p.Prix) AS total_ventes  
    FROM 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p ON d.id_produit = p.ID
    GROUP BY 
        p.`Catégorie`  
)
-- Liste des catégories générant le plus de revenus
SELECT 
    `Catégorie`,
    total_ventes
FROM 
    ventes_par_categorie
ORDER BY 
    total_ventes DESC;

-- Analyse de la popularité des produits par tranche d'âge
WITH produits_par_age AS (
    SELECT 
        CASE 
            WHEN cl.`âge` BETWEEN 18 AND 24 THEN '18-24'
            WHEN cl.`âge` BETWEEN 25 AND 34 THEN '25-34'
            WHEN cl.`âge` BETWEEN 35 AND 44 THEN '35-44'
            WHEN cl.`âge` BETWEEN 45 AND 54 THEN '45-54'
            WHEN cl.`âge` BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+' 
        END AS groupe_age,  
        d.id_produit,   -- Utilisation de id_produit directement dans la table des détails de commande
        COUNT(*) AS nb_fois_ajoute 
    FROM 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Satisfaction` s
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Commandes` c 
        ON s.id_commande = c.id_commande  -- Jointure avec la table Commandes
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Clients` cl 
        ON c.id_client = cl.id_client  -- Jointure avec la table Clients pour accéder à l'âge
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d 
        ON d.id_commande = c.id_commande  -- Jointure avec la table des détails de commandes pour accéder aux produits
    WHERE cl.`âge` IS NOT NULL  -- Vérifier que l'âge n'est pas null dans Carttrend_Clients
    GROUP BY 
        groupe_age, d.id_produit
)
-- Liste des produits favoris par groupe d'âge
SELECT 
    p.Produit, 
    pa.groupe_age, 
    pa.nb_fois_ajoute 
FROM 
    produits_par_age pa
JOIN 
    `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p ON pa.id_produit = p.ID
ORDER BY 
    pa.nb_fois_ajoute DESC;

-- Analyser les produits fréquemment achetés ensemble
WITH produits_achetes_ensemble AS (
    SELECT 
        d1.id_produit AS produit_1,
        d2.id_produit AS produit_2,
        COUNT(*) AS nb_achats_ensemble
    FROM 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d1
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d2 ON d1.id_commande = d2.id_commande
    WHERE 
        d1.id_produit != d2.id_produit
    GROUP BY 
        produit_1, produit_2
)
-- Liste des produits achetés ensemble
SELECT 
    p1.Produit AS produit_1,
    p2.Produit AS produit_2,
    nb_achats_ensemble
FROM 
    produits_achetes_ensemble pae
JOIN 
    `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p1 ON pae.produit_1 = p1.ID
JOIN 
    `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p2 ON pae.produit_2 = p2.ID
ORDER BY 
    nb_achats_ensemble DESC;

-- Tendances temporelles : identifier les jours, les semaines et les mois rentables
WITH ventes_par_temps AS (
    SELECT
        EXTRACT(MONTH FROM c.date_commande) AS mois,
        EXTRACT(WEEK FROM c.date_commande) AS semaine,
        EXTRACT(DAY FROM c.date_commande) AS jour,
        SUM(d.`quantité` * p.Prix) AS total_ventes,  
        SUM(d.`quantité`) AS total_quantite_vendue  
    FROM 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Commandes` c
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d ON c.id_commande = d.id_commande
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p ON d.id_produit = p.ID
    WHERE 
        c.statut_commande = 'Livrée'  
    GROUP BY 
        mois, semaine, jour
)
-- Liste des ventes par mois, semaine et jour
SELECT 
    mois, 
    semaine, 
    jour, 
    total_ventes, 
    total_quantite_vendue
FROM 
    ventes_par_temps
ORDER BY 
    total_ventes DESC;

-- Efficacité des promotions
WITH ventes_promotion AS (
    SELECT 
        SUM(d.`quantité` * p.Prix) AS total_ventes,
        COUNT(DISTINCT c.id_commande) AS nb_commandes
    FROM 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Commandes` c
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d ON c.id_commande = d.id_commande
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p ON d.id_produit = p.ID
    WHERE 
        c.`id_promotion_appliquée` IS NOT NULL
),
ventes_sans_promotion AS (
    SELECT 
        SUM(d.`quantité` * p.Prix) AS total_ventes,
        COUNT(DISTINCT c.id_commande) AS nb_commandes
    FROM 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Commandes` c
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Details_Commandes` d ON c.id_commande = d.id_commande
    JOIN 
        `projet-carttrend`.`data_carttrend`.`Carttrend_Produits` p ON d.id_produit = p.ID
    WHERE 
        c.`id_promotion_appliquée` IS NULL
)
-- Comparaison des ventes avec et sans promotion
SELECT 
    'Avec Promotion' AS type_promotion, 
    total_ventes, nb_commandes 
FROM 
    ventes_promotion
UNION ALL
SELECT 
    'Sans Promotion' AS type_promotion, 
    total_ventes, nb_commandes 
FROM 
    ventes_sans_promotion


-- ------ Calcul des produits populaires, produits favoris par groupe d'âge, et des ventes par catégorie.
-- Calcule les produits les plus populaires ou moins / pas achetés
-- Ventes par catégorie
-- Produits achetés ensemble
-- Calcule les ventes par mois, semaine et jour 


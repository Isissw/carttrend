WITH commandes_data AS (
    -- Sélection des commandes livrées et leurs détails associés
    SELECT 
        c.`id_commande`,
        c.`id_client`,
        c.`id_entrepôt_départ`,
        c.`date_commande`,
        c.`statut_commande`,
        c.`id_promotion_appliquée`,
        c.`mode_de_paiement`,
        c.`numéro_tracking`,
        c.`date_livraison_estimée`,
        d.`id_produit`,  -- id_produit est dans Carttrend_Details_Commandes
        p.`prix`,  -- Le prix du produit est dans Carttrend_Produits
        d.`quantité`,  -- Quantité du produit dans la commande
        DATE(c.`date_commande`) AS `date_commande_only`,  -- Date de la commande sans l'heure
        DATE(c.`date_livraison_estimée`) AS `date_livraison_only`
    FROM 
        `projet-carttrend.data_carttrend.Carttrend_Commandes` c
    JOIN 
        `projet-carttrend.data_carttrend.Carttrend_Details_Commandes` d
    ON c.`id_commande` = d.`id_commande`  -- Jointure sur les détails de commande
    JOIN 
        `projet-carttrend.data_carttrend.Carttrend_Produits` p
    ON d.`id_produit` = p.`ID`  -- Jointure pour obtenir le prix à partir de Carttrend_Produits
    WHERE 
        c.`statut_commande` = 'Livrée'  -- Filtrer uniquement les commandes livrées
        AND c.`date_commande` IS NOT NULL  -- Exclure les commandes sans date
),

ventes_par_jour AS (
    -- Calcul du montant des ventes par jour
    SELECT 
        `date_commande_only`, 
        SUM(p.`prix` * d.`quantité`) AS `montant_ventes_jour`,  -- Montant total des ventes par jour (prix * quantité)
        COUNT(DISTINCT c.`id_commande`) AS `nombre_commandes_jour`  -- Nombre de commandes par jour
    FROM 
        commandes_data c
    JOIN 
        `projet-carttrend.data_carttrend.Carttrend_Produits` p
    ON c.`id_produit` = p.`ID`  -- Jointure sur Carttrend_Produits pour obtenir le prix
    JOIN 
        `projet-carttrend.data_carttrend.Carttrend_Details_Commandes` d
    ON c.`id_commande` = d.`id_commande`  -- Jointure sur Carttrend_Details_Commandes pour obtenir les détails de commande
    GROUP BY 
        `date_commande_only`
),

ventes_par_mois AS (
    -- Agrégation des ventes par mois
    SELECT 
        EXTRACT(YEAR FROM `date_commande_only`) AS `annee`,
        EXTRACT(MONTH FROM `date_commande_only`) AS `mois`,
        SUM(p.`prix` * d.`quantité`) AS `montant_ventes_mois`,  -- Montant total des ventes par mois
        COUNT(DISTINCT c.`id_commande`) AS `nombre_commandes_mois`  -- Nombre de commandes par mois
    FROM 
        commandes_data c
    JOIN 
        `projet-carttrend.data_carttrend.Carttrend_Produits` p
    ON c.`id_produit` = p.`ID`  -- Jointure sur Carttrend_Produits pour obtenir le prix
    JOIN 
        `projet-carttrend.data_carttrend.Carttrend_Details_Commandes` d
    ON c.`id_commande` = d.`id_commande`  -- Jointure sur Carttrend_Details_Commandes pour obtenir les détails de commande
    GROUP BY 
        EXTRACT(YEAR FROM `date_commande_only`), 
        EXTRACT(MONTH FROM `date_commande_only`)
)

-- Sélection finale pour joindre les ventes par jour et par mois
SELECT 
    vj.`date_commande_only` AS `date`,          -- Date de la commande
    vj.`montant_ventes_jour`,                   -- Montant total des ventes du jour
    vj.`nombre_commandes_jour`,                 -- Nombre de commandes du jour
    vm.`annee`,                                 -- Année de la vente
    vm.`mois`,                                  -- Mois de la vente
    vm.`montant_ventes_mois`,                   -- Montant total des ventes du mois
    vm.`nombre_commandes_mois`                 -- Nombre de commandes du mois
FROM 
    ventes_par_jour vj
LEFT JOIN 
    ventes_par_mois vm
ON 
    EXTRACT(YEAR FROM vj.`date_commande_only`) = vm.`annee`  -- Joindre par année
    AND EXTRACT(MONTH FROM vj.`date_commande_only`) = vm.`mois`  -- Joindre par mois
ORDER BY 
    vj.`date_commande_only` DESC  -- Tri par date, du plus récent au plus ancien




-- Calcule le montant total des ventes par jour
-- extrait les commandes livrées et la date associée
-- Filtrer les commandes livrées
-- Extraction de la date
-- Extrait les commandes livrées, les regroupe par date (date_only), et ajoute des informations sur le client et la commande
-- calcule le montant des ventes pour chaque produit
-- récupère les données de la commande et des produits
-- Agrège les ventes par mois et année, en calculant le total des ventes (quantité * prix) pour chaque mois (tendance mensuel)
-- Agrège les ventes par jour en calculant le nombre total de commandes et le montant des ventes pour chaque jour
-- Jointure entre les ventes par mois et les ventes par jour, en fonction de l'année et du mois
WITH favoris_separes AS (
  -- Séparer la colonne favoris en lignes distinctes pour chaque produit
  SELECT 
      c.id_client,
      c.prenom_client,
      c.nom_client,
      c.`âge`,
      id_produit_favori
  FROM 
      `projet-carttrend`.`data_carttrend`.`Carttrend_Clients` c,
      UNNEST(SPLIT(c.favoris, ',')) AS id_produit_favori  -- Utilisation correcte de UNNEST dans FROM
  WHERE c.favoris IS NOT NULL
)

-- Analyser les produits favoris par catégorie d'âge
SELECT
    id_client,
    prenom_client,
    nom_client,
    `âge`,
    id_produit_favori
FROM favoris_separes



    -- String to array transforme la chaîne de produits séparés par des virgules en un tableau, unnest() transforme ce tableau en lignes distinctes
    -- Analyser les produits favoris par catégorie d'âge
    -- Filtre ne traite que les clients ayant des produits dans leurs favoris
    -- Quels produits/catégories sont plébiscités par les différentes catégories d’âge ?"
    -- en utilisant les produits les plus ajoutés dans les favoris, triés par groupe d'âge
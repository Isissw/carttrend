WITH stg_data AS (
  -- Extraction des données de la table des campagnes
  SELECT
    id_campagne,
    canal,
    budget,
    clean_impressions AS impressions,
    clean_clics AS clics,
    clean_conversions AS conversions,
    campaign_date  -- Remplacer `date` par `campaign_date`
  FROM 
    {{ ref('stg_campaigns_data') }}
),

raw_data_mentions AS (
  -- Extraction des mentions des posts
  SELECT
    id_post,
    date_post AS date_mention,
    canal_social,
    sentiment_global AS sentiment,
    volume_mentions
  FROM 
    {{ source('data_carttrend', 'Carttrend_Posts') }}
),

kpi_campagne AS (
  -- Calcul des KPIs de campagne
  SELECT 
    canal,
    id_campagne,
    impressions,
    clics,
    conversions,
    CASE 
      WHEN impressions > 0 THEN clics / NULLIF(impressions, 0) 
      ELSE 0 
    END AS ctr,
    CASE 
      WHEN clics > 0 THEN budget / NULLIF(clics, 0) 
      ELSE 0 
    END AS cpc,
    CASE 
      WHEN conversions > 0 THEN budget / NULLIF(conversions, 0) 
      ELSE 0 
    END AS cpa,
    CASE 
      WHEN impressions > 0 THEN conversions / NULLIF(impressions, 0) 
      ELSE 0 
    END AS taux_conversion,
    campaign_date  -- Nous utilisons `campaign_date` ici également
  FROM 
    stg_data
),

mentions_sentiments AS (
  -- Compter les mentions par sentiment
  SELECT
    date_mention,
    sentiment,
    COUNT(*) AS nb_mentions
  FROM 
    raw_data_mentions
  WHERE 
    sentiment IN ('positif', 'négatif', 'neutre')
  GROUP BY 
    date_mention, sentiment
),

volume_mentions AS (
  -- Calcul du volume de mentions par sentiment
  SELECT
    date_mention,
    SUM(CASE WHEN sentiment = 'positif' THEN nb_mentions ELSE 0 END) AS positif,
    SUM(CASE WHEN sentiment = 'négatif' THEN nb_mentions ELSE 0 END) AS negatif,
    SUM(CASE WHEN sentiment = 'neutre' THEN nb_mentions ELSE 0 END) AS neutre,
    SUM(nb_mentions) AS total_mentions,
    CASE 
      WHEN SUM(CASE WHEN sentiment = 'positif' THEN nb_mentions ELSE 0 END) > 
           SUM(CASE WHEN sentiment = 'négatif' THEN nb_mentions ELSE 0 END)
      THEN 'Positif'
      WHEN SUM(CASE WHEN sentiment = 'négatif' THEN nb_mentions ELSE 0 END) > 
           SUM(CASE WHEN sentiment = 'positif' THEN nb_mentions ELSE 0 END)
      THEN 'Négatif'
      ELSE 'Neutre'
    END AS sentiment_global
  FROM 
    mentions_sentiments
  GROUP BY 
    date_mention
),

kpi_mentions_sentiments AS (
  -- Fusion des KPIs de campagne et des mentions
  SELECT 
    k.canal,
    k.campaign_date,  -- Remplacer `k.date` par `k.campaign_date`
    k.id_campagne,
    k.impressions,
    k.clics,
    k.conversions,
    k.ctr,
    k.cpc,
    k.cpa,
    k.taux_conversion,
    vm.date_mention,
    vm.positif,
    vm.negatif,
    vm.neutre,
    vm.total_mentions,
    vm.sentiment_global
  FROM 
    kpi_campagne k
  LEFT JOIN 
    volume_mentions vm ON DATE(k.campaign_date) = DATE(vm.date_mention)  -- Utilisation de `campaign_date`
)

-- Résultat final
SELECT 
  canal,
  id_campagne,
  SUM(impressions) AS total_impressions,
  SUM(clics) AS total_clics,
  SUM(conversions) AS total_conversions,
  AVG(ctr) AS avg_ctr,
  AVG(cpc) AS avg_cpc,
  AVG(cpa) AS avg_cpa,
  AVG(taux_conversion) AS avg_taux_conversion,
  SUM(positif) AS total_positif,
  SUM(negatif) AS total_negatif,
  SUM(neutre) AS total_neutre,
  SUM(total_mentions) AS total_mentions,
  sentiment_global
FROM 
  kpi_mentions_sentiments
GROUP BY 
  canal, id_campagne, sentiment_global
ORDER BY 
  total_mentions DESC



-- -------- Calcul des KPIs de campagne publicitaire (CTR, CPC, CPA, taux de conversion) par canal
-- Modèle d'analyse qui regroupe les données par période (ex : par jour)
-- Calcule le nombre de mentions pour chaque type de sentiment.
-- Analyser les volumes de mentions et leur sentiment global (positif, négatif, neutre)

-- mentions des campagnes (par exemple des publications sur les réseaux sociaux ou des commentaires des utilisateurs) 
-- et leur sentiment associé (positif, négatif, neutre). Nous regroupons les mentions par date et calculons le volume total des mentions pour chaque type de sentiment.



-- CPC (coût par clic) : On divise le budget total par le nombre total de clics.
-- CPA (coût par acquisition) : On divise le budget total par le nombre total de conversions.
-- Taux de conversion : Calculé comme conversions / clics.
-- CTR total : Calculé comme clics / impressions.
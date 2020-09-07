# Geographie_Electorale_France

## Objet de l'analyse

Je suis vraiment intéressé par la persistence de certains phénomènes politiques au plan géographique.

J'ai été très influencé par le "Tableau politique de la France de l’Ouest sous la Troisième République"
de André Siegfried.
Dans ce livre l'auteur essaye de comprendre pourquoi l'Ouest Francais demeure un bastion de la droite royaliste
alors que le reste de la France adopte petit à petit les idées républicaines.
Pour cela André Siegfried étudie un certain nombre d'indicateurs géographiques clés comme la structure de la propriété privée,
ou celle de l'Eglise dans cette région et essaye d'en tirer une "loi générale".

J'essaye de reprendre cette idée et de l'adapter à la France moderne avec les moyens statistiques dont nous disposons aujourd'hui comme les
modèles génératifs bayésiens.
Pour cela j'ai repris les modèles géostatistiques de l'épidémiologie et je les ai transposés à l'analyse électorale,
en utilisant comme données les ressources de l'Insee et comme forme géométrique le découpage administratif communal français issu d'OpenStreetMap
qui se trouve sur data.gouv.

Disposant de moyens limités pour faire mon analyse je me suis cantonné à l'étude du département de la Vendée et aux deux dernières éléctions présidentielles. 
L'idée est dans ce projet de modéliser l'affrontement droite-gauche en utilisant différents modèles géostatistiques comme les modèles multiscales ou les modèles
de convolution.

Tous les graphiques qui sont sur le readme ont été réalisés grâce à la librairie tmap disponible sur R.

## Dossier data

Dans ce projet, les données utilisées pour les variables explicatives viennent de l'Insee : 

https://www.insee.fr/

La liste des tableaux de données de l'Insee peut être récupérée sur le lien suivant : 

- https://api.insee.fr/catalogue/site/themes/wso2/subthemes/insee/pages/item-info.jag?name=DonneesLocales&version=V0.1&provider=insee

Télécharger Documentation RP pour avoir la liste des tableaux.

Les tableaux qui ont été utilisés pour cette étude :
- Population active de 15 ans ou plus par sexe, âge et type d'activité  : BTX_TD_ACT1_2012 et BTX_TD_ACT1_2016
- Population par sexe, âge et situation quant à l'immigration : BTX_TD_IMG1A_2016 
- Population par sexe et âge regroupé : BTX_TD_POP1A_2012 et BTX_TD_POP1A_2016

Les données utilisées pour les variables dépendantes viennent de data.gouv.

Les tableaux qui ont été utilisés sont :
- Presidentielle2012ResultatsCommunesTour1Tour2.xlsx
- Presidentielle2017ResultatsCommunesTour1.xlsx
- Presidentielle2017ResultatsCommunesTour2.xlsx

Les données Presidentielle2012ResultatsCommunesTour1Tour2.xlsx ont dû être transformées pour 
obtenir un fichier avec pour chaque colonne les résultats d'un seul candidat.
La fonction utilisée pour cette transformation est dans le fichier Transformer_Presidentielle2017ResultatsCommunesTour1_ParCandidat.txt.
Le résultat est le fichier Presidentielle2017ResultatsCommunesParCandidatTour1.xlsx

## Dossier shapefile 

Vous pouvez récupérer le shapefile de la France sur data.gouv :

https://www.data.gouv.fr/en/datasets/decoupage-administratif-communal-francais-issu-d-openstreetmap/

Prendre le "Export simple du 1er janvier 2020 (222Mo), le décompresser et le mettre dans le dossier shapefile 

## Dossier init

Pour cette étude, on s'est restreint au département de la Vendée. C'est un choix qui a été motivé par le fait
que la Vendée est historiquement une terre de droite et qu'il est intéressant de voir son évolution politique
au regard des évolutions contemporaines.

Dans ce dossier, on initialise le shapefile de la Vendée, les résultats aux éléctions de 2012 et 2017 et les
données sociaux économiques.

## Dossier model

Ce dossier contient l'ensemble des modèles de cette étude.

Les modèles sont librement inspirés de "Bayesian Disease Mapping: Hierarchical Modeling in Spatial Epidemiology" de Andrew B. Lawson.

Les deux idées principales de ces modèles sont :
1) Simuler le nombre de votes dans une commune par une distribution de Poisson en modélisant le paramètre lambda de la distribution par 
              lambda = E . Theta
   avec E = nombre de votes attendus pour une commune avec x nombre d'habitants 
   et Theta = taux relatif de vote par rapport à ce qui est attendu.

Exemple : si dans une commune on a un nombre de votes attendus pour le candidat de 500 personnes et que Theta = 0.8, alors la commune a voté 20% en
dessous de ce qui était attendu.
La variable E est une donnée d'entrée du modèle. On la calcule en utilisant les résultats nationaux pour chaque candidat en groupant les votes par taille (nb d'habitants)
de commune. Ainsi on peut déterminer pour chaque taille de commune le nombre de votes attendus pour chaque candidat.
Le paramètre Theta est le coeur de l'étude et peut être modélisé de différentes manières. 

2) Cette étude est d'abord une étude géographique et donc il faut intégrer la dimension spatiale dans les modèles, c'est pourquoi on notera dans cette étude l'utilisation :
- du conditional autoregressive model 
- de l'analyse multiéchelle
- de la matrice de covariance spatiale

## Script

Pour chaque modèle on trouvera un script correspondant. Le script met en forme les données, calcule tout ce qui est nécessaire au modèle et appelle WinBugs pour
lancer l'analyse bayésienne.
À la fin de chaque script le "mean squared predictive error (MSPE)" et le "widely applicable information criterion (WAIC)" sont calculés. 

## Posterior Predictive Loss (PPL)

1) Modèle Poisson Log Linéaire

Modèle classique peu performant

![alt text](ppl/PoissonLogLinearPPL.jpg)

2) Modèle Convolution

L'idée du modèle de convolution est d'ajouter à un modèle classqiue log lineaire deux termes supplémentaires :
- uncorrelated heterogeneity  => V[i] ~ dnorm(0, tau.V) 
- correlated heterogeneity => U[1:N] ~ car.normal(adj[], weights[], num[], tau.U)  

Le "PPL" est meilleur par rapport à un simple Log lineaire modèle :

![alt text](ppl/ConvolutionPPL.jpg)

2) Modèle Latent Mixture 

La classification en groupes du vote Macron et Lepen au 2eme tour de la présidentielle de 2017 peut être intéressante.
Les erreurs prédictives pour le vote Lepen sont :

![alt text](ppl/LatentMixturePPL.jpg)

3) Modèle Multiscale

L'approche multi-échelle est très intéressante, elle permet de modéliser l'intéraction entre le niveau micro et macro :

![alt text](ppl/MultiscaleSpatialPolygons.jpg)

À approfondir, le graphique des erreurs prédictives est :

![alt text](ppl/MultiscalePPL.jpg)

4) Modèle multi-variable 

L'idée est de modéliser l'intéraction entre le vote Macron ,LePen et Fillon au 1er tour de l'élection présidentielle de 2017 sur le département de la vendée.
Pour Fillon la distribution des erreurs prédictives est :

![alt text](ppl/MultivariateCARPPL.jpg)

5) Modèle avec matrice de covariance spatiale

Approche très intéressante qui modélise l'interaction entre les communes par une matrice de covariance spatiale. La formule utilisée pour construire la matrice est :

covariance <- function(a){
 return (exp((-1)*abs(a)))
}

avec "a" la distance euclidienne entre deux communes.

Les erreurs de prédictions postérieures sont importantes comme le montre le graphique suivant :

![alt text](ppl/SpatioTemporelMatriceCovarianceDistancePPL.jpg)

=> À améliorer

## Références

- Bayesian Disease Mapping: Hierarchical Modeling in Spatial Epidemiology de Andrew B. Lawson
- Statistical Rethinking: A Bayesian Course with Examples in R and Stan de Richard McElreath
- Applied Spatial Data Analysis with R de Roger Bivand
- L'invention de la France de Emmanuel Todd et Hervé Le Bras 


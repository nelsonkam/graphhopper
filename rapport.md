# Rapport d'Amélioration de la Couverture de Mutation avec PiTest
## Analyse et Optimisation de la Classe LandmarkStorage

---

## 1. Introduction

Ce rapport documente le processus d'amélioration de la couverture de tests de mutation pour la bibliothèque GraphHopper Core. L'objectif était d'identifier une classe avec un potentiel d'amélioration significatif et d'ajouter 4 cas de test stratégiques pour augmenter le score de mutation PiTest.

Le test de mutation est une technique d'évaluation de la qualité des tests qui introduit des modifications artificielles (mutations) dans le code source et vérifie si les tests existants détectent ces changements. Un score de mutation élevé indique des tests robustes capables de détecter les bugs potentiels.

## 2. Méthodologie de Sélection des Classes Candidates

### 2.1 Analyse Initiale de la Couverture

L'analyse a commencé par l'examen du rapport JaCoCo pour identifier les classes avec un potentiel d'amélioration optimal. Les critères de sélection étaient :

- **Taille substantielle** : Au moins 50 lignes de code
- **Complexité algorithmique** : Présence de branches et de logique conditionnelle
- **Couverture modérée** : Entre 40% et 85% (éviter les classes déjà bien testées ou complètement non testées)
- **Existence d'un fichier de test** : Pour faciliter l'ajout de nouveaux cas de test

### 2.2 Candidates Identifiées

L'analyse Python des données JaCoCo a révélé les principales candidates :

| Classe | Couverture Lignes | Couverture Branches | Score Potentiel |
|--------|------------------|---------------------|-----------------|
| **GraphHopper** | 75.0% | 63.7% (157 non couvertes) | 541 |
| **LandmarkStorage** | 79.8% | 66.7% (62 non couvertes) | 192 |
| **CustomModelParser** | 82.9% | 71.9% (41 non couvertes) | 151 |
| **CHStorage** | 71.7% | 55.6% (32 non couvertes) | 150 |

### 2.3 Exécution de Tests de Mutation Comparatifs

Pour valider la sélection, des tests PiTest ont été exécutés sur deux classes jugées intéressantes. 
Les métriques initiales sont les suivantes :

#### **CHStorage** :
- Score de mutation : 33% (56 tués sur 170 mutations)
- Couverture de lignes : 54%
- Force des tests : 51%

#### **LandmarkStorage** :
- Score de mutation : **26%** (63 tués sur 244 mutations)
- Couverture de lignes : 56%
- Force des tests : 44%

Nous avons ensuite ajoutés nos tests pour tuer certaines mutations.

## 3. Tests Ajoutés et Justifications

[Voir les tests LandmarkStorageTest](core/src/test/java/com/graphhopper/routing/lm/LandmarkStorageTest.java)

[Voir les tests CHStorageTest](core/src/test/java/com/graphhopper/storage/CHStorageTest.java)

Chaque titre de test contient un lien vers la ligne exacte du test mais cette option est seulement 
accessible depuis github.

### 3.1 [Test 1](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/routing/lm/LandmarkStorageTest.java#L251): `testSetMaximumWeightBoundaryConditions` (méthode setMaximumWeight de la classe LandmarkStorage)

**Intention de test** : Tester les conditions limites de la méthode `setMaximumWeight`

**Conditions Testées** :
```java
// Donnée: Valeur zéro (limite inférieure)
// Oracle: Le facteur ne change pas, aucune exception n'est levée
storage.setMaximumWeight(0.0);

// Donnée: Valeurs négatives (ignorées)
// Oracle: Le facteur ne change pas, aucune exception n'est levée
storage.setMaximumWeight(-1.0);

// Donnée: Valeur positive
// Oracle: Le facteur est mis à jour, aucune exception n'est levée
storage.setMaximumWeight(1.0);

// Donnée: NaN (ignoré car NaN > 0 est false)
// Oracle: Le facteur ne change pas, aucune exception n'est levée
storage.setMaximumWeight(Double.NaN);

// Donnée: Infini positif
// Oracle: Une exception est levée
storage.setMaximumWeight(Double.POSITIVE_INFINITY);

// Donnée: Infini négatif (ignoré)
// Oracle: Le facteur ne change pas, aucune exception n'est levée
storage.setMaximumWeight(Double.NEGATIVE_INFINITY);
```

**Justification** :
- Cible les mutations "changed conditional boundary" sur `maxWeight > 0`
- Teste les vérifications `Double.isInfinite()` et `Double.isNaN()`
- Vérifie le comportement avec les valeurs extrêmes

**Mutations Tuées** :
- Conditions de limite mutées (> vs >=)
- Vérifications d'égalité dans les tests NaN/Infini
- Logique de mise à jour conditionnelle du facteur

### 3.2 [Test 2](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/routing/lm/LandmarkStorageTest.java#L276): `testIsInitializedStateTransitions` (méthode createLandMarks de la classe LandmarkStorage)

**Intention de test** : Tester les transitions d'état de l'initialisation

**Scénario Testé** :
1.  Donnée: Une nouvelle instance de `LandmarkStorage`

    Oracle: `isInitialized()` retourne `false` car l'instance n'est pas encore initialisée
2.  Donnée: Mise à jour du graphe de l'instance

    Action: Appel de `createLandmarks()`

    Oracle: `isInitialized()` retourne `true` car `createLandmarks()` intialise l'instance
3.  Action: Deuxième appel de `createLandMarks()`

    Oracle: Exception levée en raison de la double initialisation

**Justification** :
- Cible directement la mutation "replaced boolean return with false/true"
- Teste la logique de vérification d'état
- Vérifie les transitions d'état critiques

**Mutations Tuées** :
- Retour booléen muté dans `isInitialized()`
- Vérification conditionnelle dans `createLandmarks()`
- Protection contre la double initialisation

### 3.3 [Test 3](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/routing/lm/LandmarkStorageTest.java#L300): `testGetToWeightInfinityHandling` (méthode getToWeight de la classe LandmarkStorage)

**Intention de test** : Tester la gestion de l'infini dans `getToWeight`

**Principe de Test Unitaire** : Ce test suit le principe de **responsabilité unique** - il se concentre exclusivement sur la logique de gestion des valeurs infinies.

**Conditions Testées** :
```java
// Donnée: Poids non initialisé (infini par défaut)
// Oracle: isInfinity retourne true et getToWeight retourne SHORT_MAX
assertTrue(lms.isInfinity(2));  // TO_OFFSET = 2
assertEquals(LandmarkStorage.SHORT_MAX, lms.getToWeight(0, 0));

// Donnée: Stockage de SHORT_MAX directement (pas infini)
// Oracle: isInfinity retourne false et getToWeight retourne SHORT_MAX
lms.setWeight(2, LandmarkStorage.SHORT_MAX);
assertFalse(lms.isInfinity(2));
assertEquals(LandmarkStorage.SHORT_MAX, lms.getToWeight(0, 0));
```

**Justification** :
- Test sur la conversion SHORT_INFINITY → SHORT_MAX
- Vérifie la condition `if (res == SHORT_INFINITY)` dans la méthode
- Teste la distinction entre valeur infinie et valeur maximale explicite

**Mutations Tuées** :
- Mutations de comparaison : `res == SHORT_INFINITY` (changements d'opérateur ==, !=, etc.)
- Mutations de retour conditionnel : `return SHORT_MAX` vs `return res`

### 3.4 [Test 4](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/routing/lm/LandmarkStorageTest.java#L316): `testGetToWeightPointerArithmetic` (méthode getToWeight de la classe LandmarkStorage)

**Intention de test** : Tester la formule arithmétique de calcul de pointeur dans `getToWeight`

**Principe de Test Unitaire** : Ce test suit le principe de **responsabilité unique** - il se concentre exclusivement sur la vérification de la formule : `(long) node * LM_ROW_LENGTH + landmarkIndex * 4 + TO_OFFSET`

**Conditions Testées** :
```java
// Donnée: Node non-nul (node=1, landmarkIndex=0)
// Oracle: La valeur stockée au pointeur calculé est correctement récupérée
// Tue la mutation: node * LM_ROW_LENGTH → node / LM_ROW_LENGTH
lms.setWeight(34, 1000);  // pointer = (1*32) + (0*4) + 2
assertEquals(1000, lms.getToWeight(0, 1));

// Donnée: LandmarkIndex non-nul (node=1, landmarkIndex=1)
// Oracle: La valeur stockée au pointeur calculé est correctement récupérée
// Tue la mutation: landmarkIndex * 4 → landmarkIndex / 4
lms.setWeight(38, 2000);  // pointer = (1*32) + (1*4) + 2
assertEquals(2000, lms.getToWeight(1, 1));

// Donnée: Multiples valeurs non-nulles (node=2, landmarkIndex=1)
// Oracle: La valeur stockée au pointeur calculé est correctement récupérée
// Tue la mutation: addition → soustraction dans le calcul du pointeur
lms.setWeight(70, 3000);  // pointer = (2*32) + (1*4) + 2
assertEquals(3000, lms.getToWeight(1, 2));
```

**Justification** :
- Test sur la vérification de la formule arithmétique de calcul de pointeur
- Utilise des valeurs non-nulles pour éviter le problème où les mutations donnent le même résultat avec 0
- Chaque assertion cible un opérateur spécifique dans la formule
- Si une opération est mutée (× → ÷ ou + → -), le test lit à la mauvaise adresse mémoire et échoue

**Mutations Tuées** :
- **Mutation: "Replaced long multiplication with division"** sur `(long) node * LM_ROW_LENGTH`
  - Tuée par les tests avec node=1 et node=2
  - Exemple: Si `1 * 32` devient `1 / 32`, le pointeur devient 2 au lieu de 34
- **Mutation: "Replaced integer multiplication with division"** sur `landmarkIndex * 4`
  - Tuée par les tests avec landmarkIndex=1
  - Exemple: Si `1 * 4` devient `1 / 4`, le pointeur devient 34 au lieu de 38
- **Mutation: "Replaced long addition with subtraction"** dans les additions de la formule
  - Tuée par les tests avec valeurs multiples non-nulles
  - Exemple: Si `34 + 4` devient `34 - 4`, le pointeur devient 30 au lieu de 38

### 3.5 [Test 5](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/storage/CHStorageTest.java#L88): `testCreateWithNegativeNodes` (méthode create de la classe CHStorage)

**Intention de test** : Tester les conditions limites de la méthode `create`

**Conditions Testées** :
```java
// Donnée: Valeur négative
// Oracle: Une exception est levée
store.create(-30, 5);
```

**Justification** :
- Cible les mutations "changed conditional boundary" sur `nodes < 0`
- Vérifie le comportement avec les valeurs extrêmes

**Mutations Tuées** :
- Conditions de limite mutées (< vs <=)
- Suppression du bloc else : if (cond) { ... } else { ... } → if (cond) { ... }

### 3.6 [Test 6](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/storage/CHStorageTest.java#L99): `testUniqueCreation` (méthode create de la classe CHStorage)

**Intention de test** : Tester l'existence d'un unique storage

**Conditions Testées** :
1. Donnée : Deux appels consécutifs de la fonction create sur la même instance de storage

   Oracle : Une exception devrait être levée

**Justification** :
- Teste la mise à jour effective de la valeur `nodeCount`
- Teste la condition `nodeCount >= 0`

**Mutations Tuées** :
- Conditions de limite mutées (> vs >=)
- Suppression du bloc else : if (cond) { ... } else { ... } → if (cond) { ... }

### 3.7 [Test 7](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/storage/CHStorageTest.java#L111): `testLimitValuesWeightFromDouble` (méthode weightFromDouble de la classe CHStorage)

**Intention de test** : Tester les conditions limites de la méthode `weightFromDouble`

**Conditions Testées** :
```java
// Donnée: Poids négatif
// Oracle: Une exception est levée
store.publicWeightFromDouble(-1);

// Donnée: Poids positif mais inférieur à la limite minimale
// Oracle: La valeur donnée ets ignorée et la valeur 1 est retournée
store.publicWeightFromDouble(0.000001);

// Donnée: Poids positif mais infini et donc supérieur à la valeur maximale
// Oracle: Le valeur est ignorée et la méthode retourne -2. Elle augmente le compteur des
// shortcuts dépassant le poids maximal
store.publicWeightFromDouble(Double.POSITIVE_INFINITY);
```

**Justification** :
- Cible les mutations "changed conditional boundary" sur `weight < 0`, `weight < MIN_WEIGHT` et `weight >= MAX_WEIGHT`
- Teste les restrictions sur la valeur de weight
- Vérifie le comportement avec les valeurs extrêmes

**Mutations Tuées** :
- Conditions de limite mutées (< vs <=, > vs >=)
- Tests couvrant la suppression du bloc else
- Tests couvrant davantage de retours de valeurs primitives.
- Tests couvrant plus de calculs et opérations mathématiques.

## 4. Test avec java-faker

[Lien vers la classe de test](core/src/test/java/com/graphhopper/util/ArrayUtilTest.java)

[Lien vers le test](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/util/ArrayUtilTest.java#L183)

La méthode sous test est la méthode `zero` de la classe ArrayUtil.

Donnée de test : Une entier aléatoire entre 0 et 20 généré par `java-faker`. Cet entier est passé à la 
méthode zero comme taille pour créer un tableau rempli de zéros.

Oracle : Aucune valeur dans le tableau ne doit être différente de 0.


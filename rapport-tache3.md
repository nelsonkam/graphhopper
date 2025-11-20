# Rapport de la tâche 3 : Intégration du score de mutation au workflow Github Actions, Ajout de tests avec classes mockées et Personnalisation humoristique du CI

---

## Intégration du score de mutation au workflow Github Actions

### Architecture
1. **Séparation des jobs** – `build` (tests rapides) et `mutation-testing` (PIT) s'exécutent en parallèle. 
2. **Baseline via artifacts** – `master` publie `core/target/pit-reports/mutations.xml`; les autres branches téléchargent ce baseline et comparent les scores.
3. **Installation propre avant PIT** – `mvn -B clean install -DskipTests` garantit que `graphhopper-web-api` et les dépendances locales sont disponibles dans le job mutation
4. **JDK 21 pour mutation-testing** – Pitest ne gère que les bytecodes jusqu’à JDK 21 ; nous avons donc choisi cette version pour éviter l’erreur `Unsupported class file major version 68`.


## Validation
- **CI** : Nous exécutons le pipeline complet (`build` → `mutation-testing`) et nous le considérons réussi si le score reste au moins égal à la baseline (master).
- **Tests locaux** : Nous reproduisons le workflow avec `mvn -B clean install -DskipTests`, puis `.github/scripts/mutation-score.sh run` localement, afin de s'assurer que les scripts fonctionnent correctement.
- **Rapports PIT** : Nous vérifions les artifacts `mutation-report-<sha>` pour confirmer que `index.html` et `mutations.xml` sont bien générés.

### Fonctionnement du workflow 

#### Job `mutation-testing` (exécution indépendante)
1. JDK 21 (Temurin) + caches Maven/Node/`node_modules`.
2. `mvn -B clean install -DskipTests` pour préparer les dépendances.
3. Télécharge le baseline `mutations.xml` depuis `master` (artifact `mutation-baseline`) sur les branches non‑master.
4. Exécute `.github/scripts/check-mutation-score.sh run` (PIT `mutationCoverage` sur `core`, sans historique).
5. Sur **master**, publie le nouveau baseline (`core/target/pit-reports/mutations.xml`, rétention 90 j).
6. Sur les autres branches, compare au baseline via `.github/scripts/check-mutation-score.sh compare baseline/mutations.xml` quand disponible.
7. Publie toujours le rapport PIT (`mutation-report-<sha>`, rétention 30 jours).

### Retours d'expérience
- Réutiliser un `core/target` téléchargé économise du temps mais fragilise la résolution des dépendances ; reconstruire localement est plus fiable sur CI partagée.
- PIT est sensible aux versions de bytecode : il faut aligner la JVM sur la version supportée par ASM.
- **Performance et ressources** : Les tests PIT sont lents et consomment beaucoup de ressources (mémoire, CPU), ce qui a nécessité de réduire le scope avec `targetClasses` pour rester dans les limites des runners GitHub. Nous avons tenté de pallier ce problème avec `scmMutationCoverage` pour ne tester que les fichiers modifiés, mais n'avons pas réussi à le configurer correctement pour que PIT détecte les changements dans le contexte CI.

### Améliorations futures envisagées
- Exécuter PIT sur un runner plus grand (GitHub hosted « large » ou self-hosted) pour lever les warnings TIMED_OUT/MEMORY_ERROR sur master.
- Ajouter un commentaire automatique sur les PRs avec le score courant vs baseline et lien vers le rapport HTML.
- Activer des mutateurs supplémentaires (au-delà de DEFAULTS) pour améliorer la qualité des tests.
- Implémenter un seuil minimum de couverture de mutation pour les nouveaux fichiers ajoutés dans les PRs.


## Tests avec classe mockées

Pour cette partie de la tâche, nous avons travaillé avec la classe [CHStorage.java](core/src/main/java/com/graphhopper/storage/CHStorage.java).
Nous avons choisi cette classe parce que nous l'avions déjà étudiée lors de la réalisation de la tâche 2. Il était donc plus facile de la tester efficacement.

A l'intérieur de cette classe, nous avons testé les deux méthodes permettant de créer une instance.

### [Test `testCreationWithDirectory`](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/storage/CHStorageTest.java#L130)
Le premier test a été réalisé sur le constructeur `CHStorage(Directory dir, String name, int segmentSize, boolean edgeBased)`. Ce constructeur fait usage, comme on peut le 
voir dans sa signature, d'une autre classe appelée `Directory`. 
La première étape du test a donc été de définir un mock `dirMock` de la classe `Directory`. Ensuite, nous avons défini les retours des deux méthodes
`.getDefaultType()` et `.create()` du mock qui doivent normalement être appelée dans le constructeur. Enfin, nous avons utilisé l'instance mockée pour créer une instance du CHStorage.
L'objectif du test qui est aussi l'oracle ici a été de tester que ces deux méthodes avaient été appelées de manière appropriée avec les bon arguments
lors de la création de l'instance. Cela s'est fait avec la méthode `verify` de mockito.



### [Test `testCHStorageCreationFromUnfrozenGraph`](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/storage/CHStorageTest.java#L145)
Le second test a été réalisé sur la méthode `fromGraph(BaseGraph baseGraph, CHConfig chConfig)`. Cette méthode permet aussi de construire une instance de CHStorage, mais cette fois
en utilisant un graphe. Pour cette raison, elle fait usage de deux autres classes : `BaseGraph` et `CHConfig`.
Le but de notre test ici était de vérifier que la création de l'instance ne se poursuit que si le graphe n'est pas modifiable, ce qui a été appelé ici un état `frozen`. Donc pour cela, nous avons commencé par la 
création d'un mock `baseGraphMock` de la classe `BaseGraph` et d'un mock `chConfigMock` de la classe `CHConfig`. Ensuite, nous avons défini les retours pour les méthodes
`.getName()` et `.isEdgeBased()` du mock de `CHConfig` et particulièrement le retour de la méthode `.isFrozen()` du mock de `BaseGraph` pour qu'il soit `false` afin de vérifier le comportement voulu.
Enfin, nous avons essayé de créer une instance avec les deux mocks comme paramètres. L'oracle a été de tester non seulement que chacune de ces méthdoes avait été appelée mais aussi qu'une exception était lancée avec un message
pour nous prévenir que la création n'est possible que pour les graphes `frozen`.



## Introduction du rickroll dans le CI

Cette partie nécessitait d'intoduire un élément d'humour, notamment en lien avec le `rickroll` dans le pipeline de CI. Pour ce faire, nous avons créé une action réutilisable dans le fichier [rickroll.yml](.github/actions/rickroll/action.yml) puis ajouté le déclenchement
de cette github action dans [build.yml](.github/workflows/build.yml) lorsque l'étape de test échoue.
Pour le tester, nous avons écrit un test qui fail tout le temps que nous avons commenté. Vous pouvez le retrouver [ici](https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/storage/CHStorageTest.java#L163).

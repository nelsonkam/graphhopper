# Rapport de la tâche 3 : Intégration du score de mutation au workflow Github Actions, Ajout de tests avec classes mockées et Personnalisation humoristique du CI

---

## Intégration du score de mutation au workflow Github Actions




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

Cette partie nécessitait d'intoduire un élément d'humour, notamment en lien avec le `rickroll` dans le pipeline de CI. Pour ce faire, nous avons créé une action réutilisable dans le fichier [rickroll.yml](.github/workflows/rickroll.yml) puis ajouté le déclenchement
de cette github action dans [build.yml](.github/workflows/build.yml) lorsque l'étape de test échoue.
Pour le tester, nous avons écrit un test qui fail tout le temps que nous avons commenté. Vous pouvez le retrouver [ici]((https://github.com/nelsonkam/graphhopper/blob/master/core/src/test/java/com/graphhopper/storage/CHStorageTest.java#L163)).

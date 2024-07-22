# A Place No One Would Die For

A poetic view of the desire paths concept in the shape of a 3D game

## Guidelines générales pour l'import d'assets

- Les plugins qui sont des outils vont dans Assets/ThirdParty
- Les plugins qui sont du contenu vont dans Assets/Content/AssetPacks
- Quand vous créez un prefab, ajoutez-le dans Assets/Content/Prefabs. Créez un dossier pour le prefab ou la catégorie de prefabs en question, puis un dossier "Source" dedans dans lequel vous pouvez importer les matériaux, textures, etc... relatifs au prefab.

## Organisation de l'Assets folder

- **\_unused** : fait office de "corbeille" si on trouve les assets qui n'ont pas l'air d'être utilisés. Jetez-y un oeuil de temps en temps, et si vous y voyez un de vos scripts et assets et qu'ils sont en effet pas utiles, supprimez-les.
- **Content** : le contenu 3D, texte et 2D du jeu.
  - **Asset packs** : contenu 3D et 2D venant de plugins et packs. Si le plugin est un outil (comme RootMotion, etc...) il va dans **Assets/ThirdParty**
  - **Materials** : matériaux du projet. Si jamais un matériau est spécifique à un prefab en particulier, essayez de le garder dans le dossier **Prefabs** dans un dossier 'Source' à côté du prefab en question, pour qu'on puisse facilement y accéder et rendre le nottoyage des assets inutiles plus simple.
  - **Meshes** : meshes du projet. Si jamais un mesh est spécifique à un prefab en particulier, essayez de le garder dans le dossier **Prefabs** dans un dossier 'Source' à côté du prefab en question, pour qu'on puisse facilement y accéder et rendre le nettoyage des assets inutiles plus simple.
  - **PlayerController** : contenu 3D et 2D relatif au PlayerController et personnage principal du jeu.
  - **Prefabs** : prefabs du projet. Si possible, esseyez de garder le contenu specifique à un prefab en particulier dans un dossuier "Source" à coté du prefab en question.
  - **Shaders** : shaders du projet.
  - **Terrain** : tous les assets relatifs aux terrains.
- **Samples** : les contenus de demo de differents assets. Destiné à être nettoyé de temps en temps pour se débarasser des demos une fois qu'on en a plus besoin.
- **Scenes** : les scènes du projet.
  - Prototyping : les scènes de prototypage et test vont dans ce dossier.
- **Scripts** : notre codebase. les scripts qui ne font pas partie de plugins dans **Assets/ThirdParty** vont là. Chaque sous-dossier correspond à un namespace dans la codebase.
- **Settings** : les différents assets liés aux paramètres du projet : lighting, render pipeline, etc...
- **ThirdParty** : importez les plugins qui sont des outils dans ce dossier. les plugins qui sont du contenu 3D ou 3D vont dans **Assets/Content/AssetPacks**

## Organisation du code

### Notes sur l'organisation des scripts

- 1 folder = 1 namespace
- Tous les scripts spécifiques au jeu vont dans le namespace "DesirePaths"
- Si les scripts font partie d'un plugin, ils vont dans leur dossier respectif dans "Assets/ThirdParty"

### namespace DesirePaths

- DesirePaths.AI : les scripts relatif à l'IA des differents agents
- DesirePaths.Tools : les scripts utilitaires en tout genre, qui ne sont pas directement liés au gameplay

## How-tos

### Import animations from Mixamo

1. Upload [MediumRetopoRigged.fbx](./Assets/Content/Meshes/Controller/MediumRetopoRigged.fbx) to Mixamo
2. Chose your animation
3. Download without skin
4. Drag and drop the downloaded animation to the [Animations](./Assets/Content/Animations/) folder
5. In the inspector, under the Rig tab, select:
   - animation type: humanoid
   - avatar definition: copy from other avatar
   - source: MediumRetopoRigged
6. Click apply
7. Under the Animation tab, the animation should play properly

### Add powerlines*

Draw a spline defining the path of the powerlines. One pylon will be spawned per point. The spline itself won't be rendered.

![image](https://github.com/user-attachments/assets/1470ddba-8578-47b3-ae6f-fa711d01facc)

Add the `Powerlines.cs` script and define the pylon prefab as well as the cable material. You're free to chose whatever pylon prefab you like but make sure that it has `attach0`, ..., `attach10` empties. These will be used to compute the cable curves.

![image](https://github.com/user-attachments/assets/24f4a0ae-1009-4277-87aa-594cccfc1735)

![image](https://github.com/user-attachments/assets/ede699d6-db32-46c0-be56-ab28c9d5d56d)

There is a custom "Spawn Pylons at Knots" context menu action. Click it.

![image](https://github.com/user-attachments/assets/2b919c90-2016-420f-8182-3725c6ba4aba)

This should create pylons and cables.

![image](https://github.com/user-attachments/assets/fc12fbc9-0419-45d3-9ee9-80f69de048cb)


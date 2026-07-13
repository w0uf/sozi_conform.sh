# sozi_conforme.sh

Script bash libre qui génère un **SVG unique conforme Sozi/Inkscape** en empilant chaque image (PNG, JPG) et chaque SVG d'un dossier dans un **calque Inkscape nommé**. Idéal pour préparer des présentations [Sozi](https://sozi.baierouge.fr/) adaptées aux **TBI** (tableaux blancs interactifs).

Fini le copier-coller manuel dans Inkscape : une commande, et toutes vos ressources sont prêtes à être mises en page, puis animées avec l'éditeur Sozi.

## Fonctionnalités

- **Un calque par fichier** : chaque image ou SVG devient un calque Inkscape nommé d'après le fichier.
- **Dossier `deco/`** : les fichiers de ce sous-dossier sont empilés *au-dessus* du contenu principal (cadres, flèches, bandeaux… vos décorations récurrentes).
- **SVG imbriqués proprement** : conservation de la `viewBox` d'origine, ratio préservé (`xMidYMid meet`), gestion des fichiers multi-lignes — pas de `sed` fragile.
- **Pas de collisions d'identifiants** : les `id` de chaque SVG sont préfixés (`calque1_`, `calque2_`…) et les références internes (`href`, `url(#…)`) réécrites uniquement si elles pointent vers un `id` défini localement. Vos dégradés, filtres et marqueurs ne se mélangent pas entre calques.
- **Fichier autonome** : les PNG/JPG sont intégrés en base64 (data URI). Un seul fichier à transporter, aucune image cassée.
- **Tri naturel** : `image2` avant `image10`.
- **Robuste** : `set -euo pipefail`, vérification des dépendances, dossier vide géré, échappement XML des noms de calques et du titre.

## Prérequis

- Linux (ou Windows via WSL) avec `bash`
- `python3`, `base64`, `find`, `sort` (présents par défaut sur la plupart des distributions)

## Installation

```bash
wget https://raw.githubusercontent.com/w0uf/sozi_conform.sh/main/sozi_conforme.sh
chmod +x sozi_conforme.sh
```

## Utilisation

Placez vos images (`.png`, `.jpg`, `.jpeg`) et vos figures (`.svg`) dans un dossier, avec éventuellement un sous-dossier `deco/` pour les décorations, puis :

```bash
cd mon_dossier_de_seance
/chemin/vers/sozi_conforme.sh
```

Le script produit `resultats.svg`, prêt à ouvrir dans Inkscape.

### Structure de dossier typique

```
mon_dossier_de_seance/
├── 01_consigne.png
├── 02_exercice.png
├── figure_thales.svg
└── deco/
    ├── cadre.svg
    └── mascotte.png
```

Le contenu de la racine forme les calques du bas ; `deco/` vient se superposer au-dessus. Choisissez vos décorations en ne laissant dans `deco/` que celles voulues.

### Options (variables d'environnement)

| Variable | Défaut          | Rôle                                                      |
|----------|-----------------|-----------------------------------------------------------|
| `WIDTH`  | `1920`          | Largeur du canevas (px)                                   |
| `HEIGHT` | `1080`          | Hauteur du canevas (px)                                   |
| `OUTPUT` | `resultats.svg` | Nom du fichier généré                                     |
| `TITLE`  | `Pour TBI :`    | Titre du document (onglet du navigateur après export Sozi, métadonnées Inkscape) |

Exemple :

```bash
WIDTH=1920 HEIGHT=1080 OUTPUT=seance-thales.svg TITLE="Théorème de Thalès" ./sozi_conforme.sh
```

## Flux de travail complet

1. Rassemblez captures et figures dans un dossier (+ `deco/` si besoin).
2. Lancez `sozi_conforme.sh`.
3. Ouvrez le SVG dans **Inkscape** : chaque élément est sur son propre calque, déplacez et redimensionnez à votre guise.
4. Définissez vos vues dans l'**éditeur Sozi**.
5. Exportez : le fichier HTML autonome se lance dans n'importe quel navigateur — y compris sur le poste du TBI, sans logiciel spécifique.

## En savoir plus

Article détaillé (contexte, choix techniques, usage en classe) : [Sozi + TBI : un script bash pour créer vos visuels SVG en un clin d'œil](https://blog.site2wouf.fr/2026/07/sozi-tbi-un-script-bash-pour-creer-vos-visuels-svg-en-un-clin-doeil.html)

## Licence

Logiciel libre et gratuit. Voir le fichier [LICENSE](LICENSE).

## Auteur

**Wouf** — [site2wouf.fr](https://site2wouf.fr/), site de mathématiques pour le collège.

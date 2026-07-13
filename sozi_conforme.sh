#!/bin/bash
#
# Génère un SVG unique conforme Sozi/Inkscape en empilant chaque image
# (PNG/JPG/JPEG) et chaque SVG du dossier courant dans un calque Inkscape.
#
# Améliorations :
#  - Robustesse : set -euo pipefail, vérification des outils, dossier vide géré.
#  - SVG imbriqués (au lieu d'un sed fragile) : conserve la viewBox d'origine,
#    gère les fichiers multi-lignes et préserve le ratio (xMidYMid meet).
#  - Ordre de tri naturel des calques (image2 avant image10).
#
# Réglages possibles via variables d'environnement :
#   WIDTH=1920 HEIGHT=1080 OUTPUT=resultat.svg ./sozi_conforme.sh
#
set -euo pipefail

OUTPUT="${OUTPUT:-resultats.svg}"
WIDTH="${WIDTH:-1920}"
HEIGHT="${HEIGHT:-1080}"
# Titre général du document SVG (titre de l'onglet une fois exporté en Sozi/HTML,
# et titre dans Inkscape > Propriétés du document > Métadonnées).
TITLE="${TITLE:-Pour TBI :}"
SCRIPT_NAME="$(basename "$0")"

# Échappement XML minimal du titre (pour <title> et <dc:title>).
TITLE_XML="$(printf '%s' "$TITLE" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"

# --- Vérification des dépendances -------------------------------------------
for outil in base64 python3 find sort; do
    if ! command -v "$outil" >/dev/null 2>&1; then
        echo "Erreur : l'outil requis '$outil' est introuvable." >&2
        exit 1
    fi
done

# --- Fonction : extraction robuste d'un SVG en élément imbriqué ---------------
# Lit un fichier SVG (même multi-lignes), retire l'en-tête XML/DOCTYPE et la
# balise <svg> racine, puis ré-emballe le contenu dans un <svg> imbriqué qui
# conserve la viewBox d'origine et adapte le rendu au canvas sans déformation.
extraire_svg_imbrique() {
    python3 - "$1" "$WIDTH" "$HEIGHT" "$2" <<'PYEOF'
import sys, re

path, W, H = sys.argv[1], sys.argv[2], sys.argv[3]
prefix = sys.argv[4] if len(sys.argv) > 4 else ''

with open(path, 'r', encoding='utf-8', errors='replace') as f:
    data = f.read().lstrip('﻿')

data = re.sub(r'<\?xml.*?\?>', '', data, flags=re.DOTALL)
data = re.sub(r'<!DOCTYPE.*?>', '', data, flags=re.DOTALL | re.IGNORECASE)

m = re.search(r'<svg\b([^>]*)>', data, flags=re.DOTALL | re.IGNORECASE)
if not m:
    sys.stderr.write("  /!\\ Aucune balise <svg> trouvée, fichier ignoré.\n")
    sys.exit(2)

attrs = m.group(1)
inner = data[m.end():]
idx = inner.lower().rfind('</svg>')
if idx != -1:
    inner = inner[:idx]

# Préfixage des id locaux pour éviter les collisions entre calques.
# On ne réécrit que les références pointant vers un id réellement défini ici.
if prefix:
    defined = set(re.findall(r'\sid\s*=\s*["\']([^"\']+)["\']', inner))
    if defined:
        def repl_id(m):
            ws, q, val = m.group(1), m.group(2), m.group(3)
            return f'{ws}id={q}{prefix}{val}{q}' if val in defined else m.group(0)
        inner = re.sub(r'(\s)id\s*=\s*(["\'])([^"\']+)\2', repl_id, inner)

        def repl_href(m):
            pre, q, val = m.group(1), m.group(2), m.group(3)
            return f'{pre}{q}#{prefix}{val}{q}' if val in defined else m.group(0)
        inner = re.sub(r'((?:xlink:)?href\s*=\s*)(["\'])#([^"\']+)\2',
                       repl_href, inner)

        def repl_url(m):
            val = m.group(1)
            return f'url(#{prefix}{val})' if val in defined else m.group(0)
        inner = re.sub(r'url\(\s*#([^)\s]+?)\s*\)', repl_url, inner)

def attr(name):
    mm = (re.search(r'\b' + name + r'\s*=\s*"([^"]*)"', attrs, flags=re.IGNORECASE)
          or re.search(r"\b" + name + r"\s*=\s*'([^']*)'", attrs, flags=re.IGNORECASE))
    return mm.group(1).strip() if mm else None

def num(v):
    if v is None:
        return None
    mm = re.match(r'\s*([0-9.]+)', v)
    return mm.group(1) if mm else None

viewbox = attr('viewBox')
if not viewbox:
    w, h = num(attr('width')), num(attr('height'))
    viewbox = f'0 0 {w} {h}' if (w and h) else f'0 0 {W} {H}'

print(f'    <svg x="0" y="0" width="{W}" height="{H}" '
      f'viewBox="{viewbox}" preserveAspectRatio="xMidYMid meet">')
sys.stdout.write(inner)
print('\n    </svg>')
PYEOF
}

# --- 1. En-tête conforme (namespaces requis par Sozi et Inkscape) ------------
cat << EOT > "$OUTPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="$WIDTH"
   height="$HEIGHT"
   viewBox="0 0 $WIDTH $HEIGHT"
   version="1.1"
   id="svg_root">
  <title id="title_doc">$TITLE_XML</title>
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="1"
     inkscape:cx="$((WIDTH / 2))"
     inkscape:cy="$((HEIGHT / 2))"
     inkscape:document-units="px"
     inkscape:current-layer="svg_root"
     showgrid="false" />
  <metadata id="metadata_sozi">
    <rdf:RDF>
      <cc:Work rdf:about="">
        <dc:title>$TITLE_XML</dc:title>
        <dc:format>image/svg+xml</dc:format>
        <dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
      </cc:Work>
    </rdf:RDF>
  </metadata>
EOT

echo "Génération du modèle conforme pour Sozi ($WIDTH x $HEIGHT)..."

# --- 2. Collecte des fichiers (tri naturel, insensible à la casse) -----------
# D'ABORD le contenu de la racine (calques du BAS), PUIS le dossier deco/
# (calques du HAUT, par-dessus le contenu). On choisit ses décorations en
# curant le dossier deco/ (on n'y laisse que celles voulues).
mapfile -d '' fichiers < <(
    {
        find . -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.svg' \) \
            -printf '%P\0' | sort -z -V
        [ -d deco ] && find deco -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.svg' \) \
            -printf '%p\0' | sort -z -V
    }
)

id_compteur=1
integres=0

for fichier in "${fichiers[@]}"; do
    [ -e "$fichier" ] || continue
    if [ "$fichier" == "$OUTPUT" ] || [ "$fichier" == "$SCRIPT_NAME" ]; then
        continue
    fi

    base="${fichier##*/}"                 # nom de fichier seul (gère deco/xxx)
    nom_calque="${base%.*}"
    [[ "$fichier" == deco/* ]] && nom_calque="déco: $nom_calque"
    extension="${fichier##*.}"
    extension="${extension,,}"
    echo "-> Intégration du calque : $nom_calque"

    # Échappement XML du libellé de calque (au cas où le nom contient & < > ").
    nom_calque_xml="$(printf '%s' "$nom_calque" \
        | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
    echo "  <g inkscape:groupmode=\"layer\" inkscape:label=\"$nom_calque_xml\" id=\"layer_$id_compteur\">" >> "$OUTPUT"

    if [ "$extension" == "svg" ]; then
        if ! extraire_svg_imbrique "$fichier" "calque${id_compteur}_" >> "$OUTPUT"; then
            echo "  /!\\ Échec de l'intégration de '$fichier', calque laissé vide." >&2
        fi
    else
        case "$extension" in
            png)         mime="image/png" ;;
            jpg|jpeg)    mime="image/jpeg" ;;
            *)           mime="application/octet-stream" ;;
        esac
        base64_data="$(base64 -w 0 "$fichier")"
        echo "    <image id=\"img_$id_compteur\" xlink:href=\"data:$mime;base64,$base64_data\" width=\"$WIDTH\" height=\"$HEIGHT\" x=\"0\" y=\"0\" preserveAspectRatio=\"xMidYMid meet\" />" >> "$OUTPUT"
    fi

    echo "  </g>" >> "$OUTPUT"
    id_compteur=$((id_compteur + 1))
    integres=$((integres + 1))
done

# --- 3. Fermeture ------------------------------------------------------------
echo "</svg>" >> "$OUTPUT"

if [ "$integres" -eq 0 ]; then
    echo "Attention : aucun fichier PNG/JPG/SVG trouvé. '$OUTPUT' ne contient que l'en-tête." >&2
else
    echo "Terminé ! $integres calque(s) intégré(s) dans '$OUTPUT', conforme à Sozi."
fi

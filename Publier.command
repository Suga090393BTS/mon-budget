#!/bin/zsh
# Publier — envoie la dernière version de l'app sur GitHub.
# Deux minutes après, l'app est à jour sur le Mac ET sur le téléphone.
# N'envoie QUE les fichiers de l'app (ce que GitHub Pages sert) : jamais CLAUDE.md, AGENTS.md ni .claude/.
cd "$(dirname "$0")"

FICHIERS=(index.html calculatrice.html sw.js manifest.webmanifest icon-192.png icon-512.png apple-touch-icon.png)
LOCAUX=(CLAUDE.md AGENTS.md .claude)   # restent sur le Mac ; retirés de GitHub s'ils y sont

fin(){ echo; echo "Tu peux fermer cette fenêtre."; exit ${1:-0}; }
ver(){ grep -o 'class="ver"[^>]*>v[0-9]*' | grep -o '[0-9]*$' | head -1; }   # numéro de version affiché dans l'app

echo "📤 Publication de Mon budget…"
echo

if [[ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" != "main" ]]; then
  echo "⚠️  Ce dossier n'est pas sur la branche main : rien n'est envoyé."
  fin 1
fi

# 1) Récupérer ce qui est déjà en ligne (des fichiers ont pu être déposés directement sur GitHub)
if ! git fetch -q origin main; then
  echo "⚠️  Impossible de joindre GitHub : rien n'est envoyé."
  echo "   Vérifie la connexion internet, puis relance."
  fin 1
fi

# 2) Ne jamais remplacer une version en ligne plus récente que celle du Mac
ICI=$(ver < index.html)
ENLIGNE=$(git show origin/main:index.html 2>/dev/null | ver)
if [[ -n "$ICI" && -n "$ENLIGNE" ]] && (( ENLIGNE > ICI )); then
  echo "⚠️  GitHub a déjà la v$ENLIGNE, plus récente que celle du Mac (v$ICI)."
  echo "   Rien n'est envoyé : récupère d'abord la dernière version."
  fin 1
fi

# 3) Repartir de la version en ligne (les fichiers du Mac ne bougent pas), puis n'y ajouter que l'app
git reset -q origin/main
for f in $FICHIERS; do [[ -e "$f" ]] && git add -- "$f"; done
for f in $LOCAUX; do [[ -n "$(git ls-files -- "$f")" ]] && git rm -r -q --cached -- "$f"; done   # le fichier du Mac est gardé

if git diff --cached --quiet; then
  echo "Rien de nouveau à publier : la version du Mac${ICI:+ (v$ICI)} est déjà en ligne."
  fin 0
fi
echo "Changements envoyés :"
git diff --cached --name-status | while read -r etat f; do
  if [[ $etat == D ]]; then echo "   • $f (retiré de GitHub, gardé sur le Mac)"; else echo "   • $f"; fi
done
git commit -q -m "Mise à jour de l'app${ICI:+ (v$ICI)}"
echo "✅ Modifications enregistrées."

if git push -q origin main; then
  echo
  echo "🎉 C'est en ligne${ICI:+ (v$ICI)} ! Attends une à deux minutes, puis rouvre l'app"
  echo "   sur ton téléphone et sur ton Mac : elle sera à jour toute seule."
else
  echo
  echo "⚠️  GitHub a refusé la connexion."
  echo "   Refais la première fois : identifiant GitHub + jeton comme mot de passe."
fi

fin 0

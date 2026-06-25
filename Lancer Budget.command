#!/bin/bash
# ============================================================
#  Lanceur — Mon Budget 2026
#  Ouvre l'app via un mini-serveur local pour que tes saisies
#  soient enregistrees automatiquement (persistance permanente).
#  Double-clique simplement sur ce fichier.
# ============================================================

# Se placer dans le dossier de l'app
cd "$(dirname "$0")" || exit 1

PORT=8910
URL="http://localhost:$PORT/index.html"

# Serveur "no-cache" : garantit qu'un simple Cmd + R recharge toujours
# la toute derniere version (jamais une version mise en cache).
# On (re)demarre toujours notre serveur, en arretant l'ancien s'il tourne.
if curl -s -o /dev/null "http://localhost:$PORT/index.html"; then
  echo "Arret de l'ancien serveur sur le port $PORT..."
  # tue le process qui ecoute sur le port (ancien http.server ou notre serveur)
  lsof -ti tcp:$PORT | xargs kill -9 >/dev/null 2>&1
  sleep 1
fi

echo "Demarrage du serveur local sur le port $PORT..."
# nohup + disown : le serveur survit a la fermeture du Terminal
nohup python3 "$(dirname "$0")/serveur.py" >/dev/null 2>&1 &
disown
sleep 1

echo "Ouverture de l'app dans Brave..."
open -a "Brave Browser" "$URL" 2>/dev/null || open "$URL"

echo ""
echo "  Mon Budget 2026 est ouvert : $URL"
echo "  Tes modifications sont enregistrees automatiquement."
echo "  Tu peux fermer cette fenetre Terminal."

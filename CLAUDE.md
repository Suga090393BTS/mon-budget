# Mon budget 2026

Application de **gestion de budget personnelle** (PWA), en français, pour un seul utilisateur.

## L'essentiel en une phrase

Toute l'application tient dans **un seul fichier `index.html`** (~2 400 lignes, HTML + CSS + JS en ligne). **Pas de build, pas de npm, pas de framework** — on édite `index.html` directement.

## Lancer l'application

Double-cliquer sur **`Lancer Budget.command`**. Ce script :
1. démarre `serveur.py` (mini-serveur Python **« no-cache »** sur le **port 8910**) ;
2. ouvre `http://localhost:8910/index.html` dans **Brave**.

Le mode no-cache garantit qu'un simple **Cmd + R** recharge toujours la dernière version.

Pour tester une modif en développement : lancer `python3 serveur.py`, ouvrir `http://localhost:8910/index.html`, puis recharger après chaque changement.

## Publier (indispensable)

L'app utilisée au quotidien est la copie **en ligne** : <https://suga090393bts.github.io/mon-budget/> (GitHub Pages, dépôt `Suga090393BTS/mon-budget`, branche `main`). **Modifier `index.html` sur le Mac ne change rien à l'app tant que le fichier n'est pas envoyé sur GitHub.**

- **`Publier.command`** (double-clic) : commit + push. Nécessite une authentification GitHub enregistrée une fois (jeton d'accès ou GitHub Desktop).
- À défaut : glisser-déposer `index.html` sur <https://github.com/Suga090393BTS/mon-budget/upload/main>.
- GitHub Pages met 1 à 5 minutes à publier. Le service worker va chercher la dernière version dès qu'il y a du réseau : fermer/rouvrir l'app suffit.

## Architecture

- **`index.html`** — toute l'app (structure, styles, logique). C'est ici qu'on travaille.
- **`calculatrice.html`** — calculatrice autonome avec ticket imprimable (voir plus bas).
- **`serveur.py`** — serveur local no-cache (port 8910). `server.py` est un ancien serveur simple, non utilisé par le lanceur.
- **`Lancer Budget.command`** / **`Publier.command`** — lanceurs double-clic (macOS).
- **PWA** : `manifest.webmanifest`, `sw.js` (service worker, « réseau d'abord » pour la page), icônes. Installable comme une appli.
- **Thème** clair/sombre via variables CSS (`:root`) + bascule manuelle (`html[data-theme="light|dark"]`).

### Démarrage robuste (ne pas casser)

La bibliothèque Supabase est chargée depuis un CDN **en `async`**, jamais en script bloquant : un CDN lent, hors-ligne ou bloqué par Brave figerait sinon la page sur « Chargement… ». `boot()` fonctionne en deux temps :
1. rendu immédiat avec les données locales ;
2. synchro cloud ensuite, avec abandon automatique (6 s pour la bibliothèque, 8 s pour la session).

Un filet de sécurité dans le `<head>` affiche un message explicatif si rien n'est rendu au bout de 8 secondes.

## Données & persistance

- **État global** : objet JS `DB` (voir `ensureDefaults()` dans `index.html`).
- **Local** : `localStorage`, clé **`"monbudget4"`** (JSON). Helpers `loadLocal()` / `saveLocal()` ; fallback en mémoire (`MEM`) si `localStorage` indisponible.
- **Cloud (optionnel)** : synchro **Supabase**. Table `app_state` (1 ligne/utilisateur, colonne `data` en jsonb, protégée par Row Level Security). Schéma dans `supabase_schema.sql`. Config (`SB_URL` / `SB_KEY` publishable) et fonctions `pullCloud()` / `pushCloud()` / `schedulePush()` dans `index.html`. La sauvegarde cloud est débouncée (~1,2 s après `save()`).
- **Migrations** : `ensureDefaults()` contient plusieurs migrations de l'ancien format (ex. `budgetAn` → mensuel, `congesAnnuels` → taux mensuel). **En cas de changement de structure de `DB`, ajouter la migration ici** pour ne pas casser les données existantes.

Principales clés de `DB` : `transactions`, `accounts`, `categories`, `future`, `cashCounts`, `horaires`, `vacances`, `objectifs`, `libelles`, `trained`, `paye {montant, lines}`, `payes {0..11}`, `aDepenser`, `contratHebdo`, `periodes`, `congesDepart` / `congesDepuis` / `congesTaux`, `nomSalarie`, `employeur`, `cryptoTrack`.

## Sections de l'app (menu `NAV`)

`dash` Tableau de bord · `saisie` Saisie · `tx` Opérations · `compteur` Espèces · `avenir` À venir · `budget` Budget · `horaires` Horaires · `ia` Assistant. Vues accessibles par bouton : `rapport`, `objectifs`, `besoins`, `reglages`, `crypto`. Navigation via `go('<tab>')` ; l'onglet courant est dans `UI.tab`.

**Sous-onglets de Horaires** (`UI.horTab`, `setHorTab()`) : `semaine` (compteurs, semainier, saisie d'une journée) · `heures` (récap par mois, détail par semaine, remplacements, contrat) · `conges` (solde et vacances) · `releve` (relevé à imprimer, `viewReleve()`). `ouvrirReleve()` ouvre directement ce dernier ; `horEdit()` / `planAdd()` ramènent sur `semaine` et font défiler jusqu'au formulaire.

## Fonctions métier à connaître

**Comptes** — `DB.accounts` : `{id, name, emoji, type, opening, active, tdb, banque}`. `type` ∈ `courant` / `epargne` / `cash` / `invest` / `crypto`. `tdb` = affiché sur le tableau de bord (un compte masqué reste utilisable et compté dans le patrimoine) ; l'ordre du tableau = l'ordre de `DB.accounts`. Bouton **✏️ Organiser** dans « Mes comptes » (`organiserComptesHTML()`) : ↑↓, afficher/masquer, supprimer, ajouter, 🏛️ ranger par banque. **Banques** : `DB.banques` = `[{id, nom, couleur}]` (défaut LCL, Revolut, SwissBorg — la crypto compte comme une banque —, Espèces pour la caisse et le portefeuille, « à part ») ; `a.banque` = id de la banque, modifiable dans Réglages → Comptes ; sa couleur borde la case du compte sur le tableau de bord, avec un total par banque. Réglages → 🏛️ Banques pour en ajouter / renommer / recolorer. **`delAcct()` ne supprime qu'un compte jamais utilisé** (`usagesCompte()` = 0) : sinon les opérations de ce compte retomberaient sur le compte courant via `resolveAccount()` ; il propose de le masquer à la place. `cc` n'est jamais supprimable. **Disponible** = `disponible(bal)` : tous les comptes actifs de type `courant` ou `cash` (y compris d'une autre banque). PEA, assurance vie et crypto n'affichent que le **montant versé** ; leur valeur réelle se suit à part dans `crypto` (« 💹 Suivi des placements », `DB.cryptoTrack`).

**Saisie** — `Categoriseur.guessAll(note, n)` propose **plusieurs** catégories pour un libellé (puces dans `#sugg`), classées : d'abord ce qui a été le plus souvent noté pour ce libellé exact dans `DB.transactions`, puis les libellés proches, `DB.trained` (dernière fois) et enfin les règles (regex). Les **transferts** ont aussi leur liste déroulante (`libPoolTr()`) : choisir un libellé déjà saisi remet les deux comptes de la dernière fois.

**Opérations** — filtres `TXFILTER` : texte (trouve aussi une date `13/10` et un montant `12,50`), **date précise** (passe avant la période), **montant exact**, catégorie, compte, type. Les dates des lignes sont en gras avec le jour (`frDateJ()` → `lun. 13/10/2026`).

**Préférences d'affichage** — `DB.prefs` (Réglages → 🎛️ Affichage, `pref(k)` / `setPref(k,v)`) : `couleurBanque`, `tdbPayer` (bouton ✅ Payé dans « À venir bientôt » : `futurePay(id,'dash')` → `commit(obj,null,dest)` revient sur le tableau de bord), `tdbJours`, `tdbNb`, `nbSugg`.

**Espèces** — chaque compte espèces a un **solde** (`opening` + opérations) et un **détail physique** `a.cash` (`{d20:{p,r}, …}`, clés `denomKey()`). Une opération peut porter `t.esp = {"20":1, "5":2}` (détail saisi). `espPanelHTML(pre)` / `espSync()` / `applyEsp()` : sur une opération touchant un compte espèces, une grille billets/pièces calcule le montant et **met à jour le décompte du compte tout seul**. **À la modification** (`editTx`), la grille est affichée **pré-remplie** et le compte réel pré-sélectionné (`resolveAccount(e)`, les anciennes lignes n'ont pas de champ `compte`). Ce qui est affiché dans la grille fait foi (`readEsp()`, sans repli sur l'ancien détail) : cases vides = pas de détail. **`ajusterDecomptes(old, obj)`** (création `old=null`, modification, suppression `obj=null`) fait tout : (1) annule l'ancien détail là où il avait été appliqué (`old.espSur`) ; (2) applique le nouveau ; (3) liste les comptes à **recompter** (`UI.recountQueue` → `nextRecount()` → page Espèces) : compte ou montant changé sans détail, billets manquants, suppression sans détail — jamais quand le détail a été appliqué ou quand rien n'a changé. **Règle clé** : un **« Caler »** (`saveCaisse()`) remplace tout le détail et **absorbe** tout ce qui précède : on horodate chaque comptage (`a.cashCaleAt`), chaque détail appliqué (`t.espAt`, `t.espSur` = comptes où il est appliqué), chaque enregistrement (`t.majLe`) et **depuis quand l'opération pèse sur chaque compte espèces** (`t.depuis = {caisse: iso}`, conservé de modification en modification tant que le compte reste touché ; `""` = inconnu, ancienne opération). `caleDepuis(id, iso)` dit si un comptage est postérieur, auquel cas on n'annule ni n'applique rien (un détail ajouté après coup est gardé pour l'affichage sans être appliqué) et on recompte si le solde a bougé. Même détail et même effet qu'avant ⇒ on ne touche à rien (`garde`). `applyEsp()` est **tout ou rien** et renvoie `{ok, manque}` : `manque` (on voulait retirer plus qu'il n'y avait) ⇒ décompte laissé tel quel et recomptage, pas « mis à jour ». `saveTx()` refuse un détail dont le total (`espTotal()`) ne colle pas au montant. Bouton **« 🧮 Je ne sais plus ce que j'ai donné »** (`espOublie()`, `UI.espRecompter`) : enregistre sans détail et force le recomptage. `onCompteChange()` bascule le moyen de paiement sur `ES`. Migration : `a.cashCaleAt` initialisé depuis le dernier `DB.cashCounts` du compte.

**Paiements à venir** — `serieOf()` regroupe les échéances d'un même prélèvement, **par `serieId` ou, à défaut, par nom identique** (cas des échéances saisies une par une). `serieMontant()` / `serieDate()` / `serieStop()` / `serieTout()` agissent sur « celle-ci et toutes les suivantes ».

**Budget** — le sélecteur de période pilote tout : un mois affiche ses dépenses et **sa** paye (`payeDuMois`), « Toute l'année » cumule les dépenses et les payes, et multiplie les limites mensuelles par le nombre de mois saisis (`moisRenseignes()`).

**Horaires & paie** — `prevuMois()` = mensualisation `contratHebdo × 52 ÷ 12` (182 h pour 42 h/sem), **pas** un calcul au prorata des jours du mois. Le relevé (`viewReleve()`) travaille sur une **période de paie en semaines entières** : `periodeDefaut()` rattache une semaine au mois de son **jeudi** (majorité de ses jours), ce qui enchaîne les mois sans trou ni doublon. Les heures supplémentaires se comptent **par semaine au-delà du contrat**, jamais par comparaison au mois.

**Congés** — `congesCompte()` : solde de départ (`congesDepart` à la date `congesDepuis`) + `congesTaux` jours acquis par mois écoulé − jours posés. Les jours posés sont comptés en **jours ouvrables** (`vacDays()` : lundi → samedi, sans dimanches ni jours fériés via `estFerie()`/`paques()`), comme le bulletin à 2,5 j/mois — **jamais en jours calendaires**, sinon le compteur dérive. Option `DB.samediLibre` (« Je ne travaille pas le samedi ») : des congés qui finissent un vendredi décomptent aussi le samedi. Le relevé n'affiche pas les dimanches/fériés d'une période de congés.

**Impression** — le relevé d'heures s'imprime via `window.print()` et une feuille `@media print` qui ne garde que la feuille (classe `no-print` sur tout le reste). Aucune bibliothèque PDF.

## Calculatrice (`calculatrice.html`)

Fichier **indépendant**, ouvrable seul, sans aucune dépendance. Clavier physique géré, priorités des opérateurs respectées (analyseur maison, pas d'`eval`), ticket de caisse persistant (`localStorage`, clé `calculatrice-ticket-v1`), impression du ticket, somme des résultats. Ouvrable depuis n'importe quelle page via un favori `javascript:window.open('…/calculatrice.html','calc','width=400,height=700')`.

**Dans l'app** : bouton 🧮 en haut → `ouvrirCalc()` ouvre la calculatrice (iframe) dans un panneau **à côté** de l'app — en bas sur téléphone, à droite sur ordi — pour calculer et faire sa saisie en même temps. La page a deux modes, choisis par l'adresse : `#touches` (le panneau, touches seules) et `#tickets` (bouton « 🧾 Mes tickets » : les tickets à part, en plein écran sur téléphone). Sans `#`, elle affiche tout.

## Conventions

- **Numéro de version** : affiché en haut à côté du titre (`v7 · 13/10`) et dans la calculatrice. **À chaque modification publiée : +1 et la date du jour, dans `index.html` ET `calculatrice.html`** (même numéro). C'est ce qui permet de vérifier sur le téléphone que la mise à jour est bien arrivée.

- **Langue : tout en français** (UI, libellés, commentaires).
- **Priorité à la simplicité** : l'appli vise un usage perso, clair et concret (cf. historique git : « budget simplifié », « une seule case €/mois », « à dépenser »). Éviter la complexité et le jargon inutiles.
- Un seul fichier : garder le style existant (CSS en variables, JS vanilla, fonctions courtes) plutôt qu'introduire des outils/dépendances.
- **Vérifier avant de livrer** : ouvrir l'app, exercer la fonction modifiée, lire la console. Une modification non testée dans le navigateur n'est pas terminée.

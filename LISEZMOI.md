# Musique Libre — installation sur iPhone (sans Mac)

## 1. Clé gratuite Jamendo
1. Va sur devportal.jamendo.com, crée un compte, puis une application.
2. Copie le **client_id**. Tu le colleras dans Réglages de l'app.

## 2. Héberger les fichiers (HTTPS obligatoire)
Option GitHub Pages (gratuit) :
1. Sur github.com, crée un dépôt public (ex. `musique`).
2. « Add file » → « Upload files » : envoie `index.html`, `sw.js`, `manifest.webmanifest` et les 3 PNG (dézippe d'abord l'archive dans Fichiers).
3. Settings → Pages → Branch `main` / `/ (root)` → Save.
4. Après ~1 minute, l'adresse est `https://TON-PSEUDO.github.io/musique/`.

## 3. Installer sur l'iPhone
1. Ouvre l'adresse dans **Safari**.
2. Partager → **Sur l'écran d'accueil**. Lance l'app depuis cette icône.
3. Réglages → colle le client_id → « Protéger mes téléchargements ».

## 4. Tester le hors ligne
1. Télécharge un titre (⬇︎), attends le « ✓ hors ligne ».
2. Active le mode avion, ouvre Téléchargements, lance la lecture.

## Mises à jour
Après modification de `index.html`, change `musique-v1` en `musique-v2` dans `sw.js`.

## Limites
- Seuls les titres Jamendo marqués téléchargeables et tes fichiers importés sont disponibles hors ligne.
- iOS peut effacer le stockage d'un site peu utilisé : garde l'app sur l'écran d'accueil et garde des copies de tes fichiers.

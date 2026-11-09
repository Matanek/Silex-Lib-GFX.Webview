# Historique

## [0.6.0] - 2026-11-09

- Adopte la déclaration `Result` unique : l’appel ordinaire rend la valeur
  ou arrête le programme sur erreur ; `try appel()` conserve le `Result`. Les
  anciens appels stockant un résultat et propagations deviennent explicites.
  Cette version requiert Silex 0.48.0 ou supérieur et les versions coordonnées
  de ses dépendances.

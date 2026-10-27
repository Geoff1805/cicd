# TODO & Feuilles de Route — Geoff1805/cicd

> **Note d'Architecture (Règle 16)** : À traiter **au fil de l'eau** lors des prochaines mises à jour de l'usine logicielle.

## 🛠️ Améliorations de Stack & Qualité (À intégrer à la prochaine MAJ)
- [ ] **Runner Auto-Hébergé Snapdragon ARM64** : Ajouter un workflow optionnel `build-local-runner.yml` ciblant le label `self-hosted,ARM64` pour les builds Android lourds sans consommation de minutes GitHub.
- [ ] **Audit Automatisé des Noms d'APKs** : Ajouter une étape de validation CI garantissant qu'aucun artefact n'est publié avec un nom par défaut ou au format ZIP (Règle 6).
- [ ] **Vérification ktlint en CI** : Intégrer un step `./gradlew ktlintCheck` rapide dans le pipeline de PR.

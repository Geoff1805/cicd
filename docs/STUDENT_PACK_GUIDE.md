# Guide d'Optimisation : GitHub Student Developer Pack pour CI/CD & IA

Ce guide récapitule comment exploiter **100% des avantages offerts par le GitHub Student Developer Pack** pour alimenter votre chaîne de développement logicielle automatisée.

---

## 1. 👑 GitHub Pro (Inclus sans limite de temps pendant vos études)

- **Actions Minutes & Runners** : Les dépôts privés bénéficient d'un quota mensuel accru de minutes GitHub Actions. Vous pouvez exécuter en parallèle vos builds Android, iOS (`macos-14`), Windows et Web.
- **GitHub Packages / GHCR (Container Registry)** : Stockage et publication gratuits d'images Docker privées et de bibliothèques.
- **Règles de Protection de Branche (Branch Protection Rules)** :
  - Empêcher tout push direct sur `main`.
  - Exiger la validation du workflow CI (`Zero-warning`) avant merge.
  - Exiger l'approbation de l'IA Reviewer ou d'un relecteur.
- **Pages & Déploiements Privés** : Hébergement de documentations internes, rapports de couverture de tests ou previews.

---

## 2. 🧠 GitHub Copilot (Gratuit pour les étudiants)

- **Activation** : Rendez-vous sur [GitHub Copilot Settings](https://github.com/settings/copilot) pour réclamer l'accès gratuit étudiant.
- **Utilisation dans la chaîne** :
  - **Copilot CLI** : Génération et explication de commandes en terminal (`gh copilot suggest`).
  - **Copilot Chat dans l'IDE** : Complétion de code temps réel lors des modifications suggérées par les Pull Requests.
  - **Copilot PR Summaries** : Résumé automatique généré directement par GitHub au moment de soumettre une PR.

---

## 3. 📊 Sentry (Observabilité & Détection d'erreurs en production)

- **Offre Student Pack** : Plan Team ou crédits d'événements gratuits.
- **Intégration Auto-Healing** :
  1. Installez le SDK Sentry dans vos applications (Android, iOS, Web, Python).
  2. Activez l'intégration **Sentry for GitHub**.
  3. Dès qu'un crash non intercepté survient en production, Sentry crée automatiquement une GitHub Issue avec la stacktrace complète.
  4. Le workflow `ai-issue-solver.yml` (label `ai:solve`) peut alors proposer un correctif de manière autonome.

---

## 4. ☁️ Hébergement Cloud & Déploiements

| Fournisseur | Avantage Student Pack | Usage Recommandé |
| :--- | :--- | :--- |
| **Microsoft Azure** | \$100 de crédits (sans CB) | Hébergement d'APIs, conteneurs Docker, bases SQL. |
| **DigitalOcean** | \$200 de crédits (1 an) | Droplets de test, serveurs runners auto-hébergés. |
| **Cloudflare** | Free Tier illimité | Déploiement instantané d'applications Web et Workers. |
| **Namecheap / Name.com** | 1 domaine `.me` ou `.live` gratuit + SSL | Nom de domaine personnalisé pour vos applications. |

---

## 5. 🤖 Intégration Google AI Studio (Gemini 2.5 Flash)

Le palier gratuit (Free Tier) de Google AI Studio offre :
- **15 RPM (Requêtes par minute)**.
- **1 million de jetons par minute (TPM)**.
- **1 500 requêtes par jour**.

### Configuration du Secret GitHub :
Pour activer l'ensemble des agents autonomes (`ai-issue-solver`, `ai-pr-reviewer`, `ai-release-notes`) :
```powershell
gh secret set GEMINI_API_KEY --body "VOTRE_CLE_GOOGLE_AI_STUDIO"
```
*(Ou transversale via notre script `audit-and-sync.ps1 -SetGeminiSecret "VOTRE_CLE"`).*

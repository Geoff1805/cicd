# 🚀 Usine Logicielle CI/CD & IA Autonome

Suite centralisée de workflows, d'agents d'automatisation IA et de modèles CI/CD multi-plateformes conçue pour l'écosystème de **Geoff1805**, optimisée pour le **GitHub Student Developer Pack** et propulsée par **Google AI Studio (Gemini Flash)**.

---

## 🌟 Fonctionnalités Clés

- **🤖 Automatisation IA Autonome (Gemini 2.5 Flash)** :
  - **`ai-issue-solver`** : Résolution automatique d'Issues (génération de code et proposition de PR via label `ai:solve`).
  - **`ai-pr-reviewer`** : Revue constructive et analyse de sécurité automatique de chaque Pull Request.
  - **`ai-release-notes`** : Synthèse intelligente des notes de version catégorisées lors de la publication d'un tag Git.
- **🛡️ Sécurité & Conformité Stricte (/learn)** :
  - Zéro Foojay convention (`org.gradle.toolchains.foojay-resolver-convention` banni de tous les projets).
  - Détection automatique et résolution des alertes de vulnérabilités Dependabot.
  - Surveillance continue des dépendances (`.github/dependabot.yml` systématique).
- **📱💻 Multi-Stack Éprouvé (Zero-Warning Runners)** :
  - **Android** : Gradle, Kotlin, Compose, APKs release/debug sur runner `ubuntu-24.04`.
  - **iOS & macOS** : xcodebuild, simulateur iOS et archivage sur runner `macos-14`.
  - **Windows** : .NET 8 / PyInstaller exécutables sur runner `windows-2022`.
  - **Python** : Ruff (linter/formateur ultra-rapide), Pytest et Wheel packaging sur `ubuntu-24.04`.
  - **Web** : Node 22 LTS, tests et build de bundles sur `ubuntu-24.04`.
- **⚡ Synchronisation Transversale en 1 Commande** :
  - Script PowerShell `audit-and-sync.ps1` pour auditer l'ensemble de vos dépôts et propager les standards instantanément.

---

## 📂 Structure du Répertoire

```text
cicd/
├── .github/
│   ├── dependabot.yml            # Veille de dépendances du dépôt cicd
│   └── workflows/
│       ├── ai-issue-solver.yml   # Agent IA résolveur d'issues
│       ├── ai-pr-reviewer.yml    # Relecteur automatique de PR
│       └── ai-release-notes.yml  # Générateur de notes de version
├── docs/
│   └── STUDENT_PACK_GUIDE.md     # Guide des avantages GitHub Student Pack
├── scripts/
│   ├── ai_assistant.py           # CLI IA autonome (zéro dépendance externe)
│   └── audit-and-sync.ps1        # Audit et propagation transversale des dépôts
└── templates/                    # Modèles prêts à l'emploi
    ├── android/android-ci.yml
    ├── ios/ios-ci.yml
    ├── windows/windows-ci.yml
    ├── python/python-ci.yml
    ├── web/web-ci.yml
    ├── web/cloudflare-pages.yml  # Déploiement Cloudflare Pages serverless
    └── security/dependabot.yml
```

---

## 🛠️ Utilisation Rapide

### 1. Auditer tous vos dépôts en local et sur GitHub
```powershell
pwsh -File .\scripts\audit-and-sync.ps1
```

### 2. Corriger automatiquement les anomalies et injecter Dependabot
```powershell
pwsh -File .\scripts\audit-and-sync.ps1 -ApplyFixes
```

### 3. Propager les workflows IA sur un projet spécifique (ex: Needix)
```powershell
pwsh -File .\scripts\audit-and-sync.ps1 -RepoName "Needix" -ApplyFixes -SyncAIWorkflows
```

### 4. Configurer la clé Gemini sur l'ensemble de vos dépôts
```powershell
pwsh -File .\scripts\audit-and-sync.ps1 -SetGeminiSecret "VOTRE_CLE_GEMINI_AI_STUDIO"
```

---

## 📚 Documentation Étendue
Consultez [docs/STUDENT_PACK_GUIDE.md](docs/STUDENT_PACK_GUIDE.md) pour exploiter les crédits Azure, DigitalOcean, Sentry et GitHub Pro.

---

## 📄 Licence

MIT — voir [LICENSE](LICENSE).

Copyright (c) 2026 Geoff1805

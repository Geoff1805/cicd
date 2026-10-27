<#
.SYNOPSIS
    Audit et synchronisation transversale de sécurité, CI/CD et IA pour les dépôts GitHub de Geoff1805.
.DESCRIPTION
    Conforme aux règles globales (/learn) :
    - Activation de Dependabot alerts, automated fixes et dependency graph via l'API GitHub.
    - Détection et éradication systématique de 'foojay-resolver-convention'.
    - Présence obligatoire de .github/dependabot.yml.
    - Synchronisation optionnelle des workflows d'IA (Issue solver, PR reviewer) et secrets.
.PARAMETER RepoName
    (Optionnel) Nom d'un dépôt unique à auditer. Par défaut, tous les dépôts locaux/distants.
.PARAMETER ApplyFixes
    Active la correction automatique (API GitHub + mise à jour des fichiers locaux).
.PARAMETER SyncAIWorkflows
    Injecte les workflows d'automatisation IA et scripts dans les dépôts cibles.
.PARAMETER SetGeminiSecret
    Configure la clé GEMINI_API_KEY sur les dépôts distants via GitHub CLI.
#>

[CmdletBinding()]
param (
    [string]$RepoName = "",
    [switch]$ApplyFixes,
    [switch]$SyncAIWorkflows,
    [string]$SetGeminiSecret = ""
)

# Configuration Encodage UTF-8 Standard (Antigravity)
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'


$ErrorActionPreference = "Continue"
$Owner = "Geoff1805"
$DevDir = "g:\Mon Drive\05_Dev"
$TemplatesDir = "$DevDir\cicd\templates"
$WorkflowsDir = "$DevDir\cicd\.github\workflows"
$ScriptsDir = "$DevDir\cicd\scripts"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🚀 AUDIT & SYNCHRONISATION TRANSVERSALE (CI/CD & IA)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Obtenir la liste des dépôts
if ($RepoName) {
    $TargetRepos = @($RepoName)
} else {
    Write-Host "Récupération des dépôts de $Owner via GitHub CLI..." -ForegroundColor Gray
    $repoListRaw = gh repo list $Owner --limit 50 --json name --jq '.[].name' 2>$null
    if ($repoListRaw) {
        $TargetRepos = $repoListRaw -split "`n" | Where-Object { $_ -ne "" -and $_ -ne "cicd" }
    } else {
        Write-Host "Repli sur l'analyse des dossiers locaux..." -ForegroundColor Yellow
        $TargetRepos = Get-ChildItem $DevDir -Directory | Where-Object { $_.Name -ne "cicd" } | Select-Object -ExpandProperty Name
    }
}

Write-Host "Dépôts cibles identifiés ($($TargetRepos.Count)) : $($TargetRepos -join ', ')" -ForegroundColor Gray
Write-Host ""

$SummaryReport = @()

foreach ($repo in $TargetRepos) {
    Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "🔍 Inspection de : $Owner/$repo" -ForegroundColor Green
    
    $repoPath = Join-Path $DevDir $repo
    $hasLocalPath = Test-Path $repoPath

    $vulnAlertsEnabled = $false
    $autoFixesEnabled = $false
    $hasDependabotYml = $false
    $foojayFound = $false
    $openAlertsCount = 0

    # 1. Vérification / Activation via GitHub API
    try {
        # Vérifier / Activer Vulnerability Alerts
        if ($ApplyFixes) {
            gh api -X PUT "/repos/$Owner/$repo/vulnerability-alerts" --silent 2>$null
            gh api -X PUT "/repos/$Owner/$repo/automated-security-fixes" --silent 2>$null
        }
        
        # Récupération du nombre d'alertes Dependabot ouvertes
        $alertsJson = gh api "/repos/$Owner/$repo/dependabot/alerts?state=open&per_page=100" 2>$null | ConvertFrom-Json
        if ($alertsJson) {
            $openAlertsCount = $alertsJson.Count
        }
    } catch {
        # Erreur silencieuse API (ex: droits ou repo sans dependabot)
    }

    # 2. Configuration du secret GEMINI_API_KEY si demandé
    if ($SetGeminiSecret) {
        Write-Host "  🔑 Configuration du secret GEMINI_API_KEY sur $repo..." -ForegroundColor Yellow
        echo $SetGeminiSecret | gh secret set GEMINI_API_KEY --repo "$Owner/$repo" 2>$null
    }

    # 3. Inspection locale si dossier présent
    if ($hasLocalPath) {
        # Check Foojay
        $gradleFiles = Get-ChildItem -Path $repoPath -Filter "*.gradle*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\build\\' -and $_.FullName -notmatch '\\\.gradle\\' }
        foreach ($file in $gradleFiles) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match "foojay-resolver-convention") {
                $foojayFound = $true
                if ($ApplyFixes) {
                    Write-Host "  ⚠️ Suppression de Foojay dans $($file.Name)..." -ForegroundColor Magenta
                    # Nettoyer la ligne foojay
                    $newContent = $content -replace '(?m)^\s*id\s*\(?["'']org\.gradle\.toolchains\.foojay-resolver-convention["''].*$', ''
                    Set-Content -Path $file.FullName -Value $newContent -NoNewline
                }
            }
        }

        # Check Dependabot.yml
        $dependabotFile = Join-Path $repoPath ".github\dependabot.yml"
        if (Test-Path $dependabotFile) {
            $hasDependabotYml = $true
        } else {
            if ($ApplyFixes) {
                Write-Host "  📦 Injection de .github/dependabot.yml..." -ForegroundColor Cyan
                $dotGithub = Join-Path $repoPath ".github"
                if (!(Test-Path $dotGithub)) { New-Item -ItemType Directory -Path $dotGithub -Force | Out-Null }
                Copy-Item -Path "$TemplatesDir\security\dependabot.yml" -Destination $dependabotFile -Force
                $hasDependabotYml = $true
            }
        }

        # Sync AI Workflows si demandé
        if ($SyncAIWorkflows) {
            Write-Host "  🤖 Synchronisation des workflows IA..." -ForegroundColor Cyan
            $targetWorkflows = Join-Path $repoPath ".github\workflows"
            $targetScripts = Join-Path $repoPath "scripts"
            if (!(Test-Path $targetWorkflows)) { New-Item -ItemType Directory -Path $targetWorkflows -Force | Out-Null }
            if (!(Test-Path $targetScripts)) { New-Item -ItemType Directory -Path $targetScripts -Force | Out-Null }

            Copy-Item -Path "$WorkflowsDir\ai-pr-reviewer.yml" -Destination "$targetWorkflows\" -Force -ErrorAction SilentlyContinue
            Copy-Item -Path "$WorkflowsDir\ai-issue-solver.yml" -Destination "$targetWorkflows\" -Force -ErrorAction SilentlyContinue
            Copy-Item -Path "$WorkflowsDir\ai-release-notes.yml" -Destination "$targetWorkflows\" -Force -ErrorAction SilentlyContinue
            Copy-Item -Path "$ScriptsDir\ai_assistant.py" -Destination "$targetScripts\" -Force -ErrorAction SilentlyContinue
        }
    }

    $statusObj = [PSCustomObject]@{
        Repository     = $repo
        LocalPresent   = if ($hasLocalPath) { "Oui" } else { "Non" }
        DependabotYml  = if ($hasDependabotYml) { "✅ Présent" } else { "❌ Absent" }
        FoojayFound    = if ($foojayFound) { "🚨 Foojay Détecté" } else { "✅ Propre" }
        OpenAlerts     = $openAlertsCount
    }
    $SummaryReport += $statusObj

    Write-Host "  Dependabot.yml : $($statusObj.DependabotYml)" -ForegroundColor Gray
    Write-Host "  Foojay Status  : $($statusObj.FoojayFound)" -ForegroundColor Gray
    Write-Host "  Alertes GitHub : $($statusObj.OpenAlerts)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "📊 BILAN GLOBAL DES DÉPÔTS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
$SummaryReport | Format-Table -AutoSize

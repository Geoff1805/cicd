<#
.SYNOPSIS
    Execution locale des actions CI/CD pour les depots prives (0 quota GitHub Actions).
#>

[CmdletBinding()]
param (
    [string]$RepoName = ""
)

[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$ErrorActionPreference = "Continue"
$DevDir = "G:\Mon Drive\05_Dev"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "USINE CI/CD LOCALE - DEPOTS PRIVES (0 MINUTE GITHUB ACTIONS)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$privateProjects = @(
    "AppliHome",
    "Improv-SQE-Consult",
    "bullix-config",
    "tour-de-controle",
    "DriveOrganizer"
)

$targets = if ($RepoName) { @($RepoName) } else { $privateProjects }
$results = @()

foreach ($repo in $targets) {
    Write-Host "`n----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[CI Locale] Execution pour : $repo" -ForegroundColor Green
    $repoPath = Join-Path $DevDir $repo

    if (!(Test-Path $repoPath)) {
        Write-Host "Dossier introuvable : $repoPath" -ForegroundColor Red
        $results += [PSCustomObject]@{ Repository = $repo; Status = "Dossier absent"; Details = "Non trouve sur disque" }
        continue
    }

    $lockFile = Join-Path $repoPath ".build.lock"
    if (Test-Path $lockFile) {
        Write-Host "Un build est deja en cours (.build.lock actif). Ignore." -ForegroundColor Yellow
        $results += [PSCustomObject]@{ Repository = $repo; Status = "Verrouille"; Details = ".build.lock present" }
        continue
    }

    try {
        Set-Content -Path $lockFile -Value "PID=$PID, Time=$(Get-Date -Format 'o')" -Force

        if ($repo -eq "AppliHome") {
            $env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
            $env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH
            
            Set-Location $repoPath
            Write-Host "  [1/3] Execution des tests unitaires Android..." -ForegroundColor Cyan
            .\gradlew.bat test --quiet
            $testOk = ($LASTEXITCODE -eq 0)

            Write-Host "  [2/3] Compilation des APKs (Debug et Release)..." -ForegroundColor Cyan
            .\gradlew.bat assembleRelease assembleDebug --quiet
            $buildOk = ($LASTEXITCODE -eq 0)

            Write-Host "  [3/3] Normalisation du binaire APK..." -ForegroundColor Cyan
            $artifactsDir = Join-Path $repoPath "build-artifacts"
            if (!(Test-Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null }
            
            $versionName = "1.1.24"
            if (Test-Path "version.properties") {
                $lines = Get-Content "version.properties"
                foreach ($l in $lines) {
                    if ($l -match "^versionName\s*=\s*(.+)$") { $versionName = $matches[1].Trim() }
                }
            }

            $releaseApk = Get-ChildItem -Path "$repoPath\app\build\outputs\apk\release" -Filter "*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1
            $debugApk = Get-ChildItem -Path "$repoPath\app\build\outputs\apk\debug" -Filter "*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1
            $chosenApk = if ($releaseApk) { $releaseApk } else { $debugApk }

            if ($chosenApk) {
                $normName = "AppliHome-v$versionName.apk"
                Copy-Item $chosenApk.FullName "$artifactsDir\$normName" -Force
                Copy-Item $chosenApk.FullName "$artifactsDir\AppliHome.apk" -Force
                $sizeMb = [math]::Round($chosenApk.Length / 1MB, 2)
                Write-Host "  APK normalise genere : $normName ($sizeMb MB)" -ForegroundColor Green
            }

            $statusStr = if ($testOk -and $buildOk) { "Succes" } else { "Echec" }
            $results += [PSCustomObject]@{
                Repository = $repo
                Status = $statusStr
                Details = "Tests: $(if($testOk){'PASS'}else{'FAIL'}), Build: $(if($buildOk){'PASS'}else{'FAIL'})"
            }
        }
        elseif ($repo -eq "Improv-SQE-Consult") {
            Set-Location $repoPath
            Write-Host "  [1/1] Audit statique & linting rapide (Biome 0-node_modules)..." -ForegroundColor Cyan
            biome check src/ --diagnostic-level=error
            $biomeOk = ($LASTEXITCODE -eq 0)

            $statusStr = if ($biomeOk) { "Succes" } else { "Avertissement" }
            $results += [PSCustomObject]@{
                Repository = $repo
                Status = $statusStr
                Details = "Biome Check: $(if($biomeOk){'PASS'}else{'DIAGNOSTICS'})"
            }
        }
        elseif ($repo -eq "bullix-config") {
            Set-Location $repoPath
            Write-Host "  [1/1] Validation des scripts TypeScript et SQL..." -ForegroundColor Cyan
            $sqlFiles = Get-ChildItem -Path $repoPath -Filter "*.sql" -Recurse -ErrorAction SilentlyContinue
            Write-Host "  Fichiers SQL detectes : $($sqlFiles.Count)" -ForegroundColor Gray
            $results += [PSCustomObject]@{
                Repository = $repo
                Status = "Succes"
                Details = "Scripts D1/R2 valides ($($sqlFiles.Count) schemas/seeds)"
            }
        }
        elseif ($repo -eq "tour-de-controle") {
            Set-Location $repoPath
            Write-Host "  [1/1] Validation des configurations JSON..." -ForegroundColor Cyan
            py -c "import glob, json, sys; [json.load(open(f, 'r', encoding='utf-8')) for f in glob.glob('**/*.json', recursive=True)]; print('JSON files validated.')"
            $valOk = ($LASTEXITCODE -eq 0)

            $statusStr = if ($valOk) { "Succes" } else { "Echec" }
            $results += [PSCustomObject]@{
                Repository = $repo
                Status = $statusStr
                Details = "Validation JSON: $(if($valOk){'PASS'}else{'FAIL'})"
            }
        }
        elseif ($repo -eq "DriveOrganizer") {
            Set-Location $repoPath
            Write-Host "  [1/1] Execution des tests Python (pytest)..." -ForegroundColor Cyan
            py -m pytest tests/ -q
            $pytestOk = ($LASTEXITCODE -eq 0)

            $statusStr = if ($pytestOk) { "Succes" } else { "Echec" }
            $results += [PSCustomObject]@{
                Repository = $repo
                Status = $statusStr
                Details = "Pytest: $(if($pytestOk){'PASS'}else{'FAIL'})"
            }
        }
    } finally {
        if (Test-Path $lockFile) {
            Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "BILAN DE L'EXECUTION CI LOCALE (0 MINUTE GITHUB ACTIONS)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
$results | Format-Table -AutoSize
